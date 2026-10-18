package math

import (
	"fmt"
	"time"
)

var ShamsiMonthNames = [12]string{
	"فروردین",
	"اردیبهشت",
	"خرداد",
	"تیر",
	"مرداد",
	"شهریور",
	"مهر",
	"آبان",
	"آذر",
	"دی",
	"بهمن",
	"اسفند",
}

var ShamsiWeekdayNames = [7]string{
	"شنبه",
	"یکشنبه",
	"دوشنبه",
	"سه شنبه",
	"چهارشنبه",
	"پنجشنبه",
	"جمعه",
}

type ShamsiDate struct {
	Year        int    `json:"year"`
	Month       int    `json:"month"`
	Day         int    `json:"day"`
	Hour        int    `json:"hour"`
	Minute      int    `json:"minute"`
	Second      int    `json:"second"`
	MonthName   string `json:"month_name"`
	WeekdayName string `json:"weekday_name"`
	Formatted   string `json:"formatted"`
}

// GregorianToShamsi converts Gregorian year, month, day to Jalali (Shamsi) year, month, day.
func GregorianToShamsi(gy, gm, gd int) (jy, jm, jd int) {
	gDaysInMonth := [12]int{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	jDaysInMonth := [12]int{31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29}

	gy2 := gy - 1600
	gm2 := gm - 1
	gd2 := gd - 1

	gDayNo := 365*gy2 + (gy2+3)/4 - (gy2+99)/100 + (gy2+399)/400

	for i := 0; i < gm2; i++ {
		gDayNo += gDaysInMonth[i]
	}
	if gm2 > 1 && ((gy%4 == 0 && gy%100 != 0) || (gy%400 == 0)) {
		gDayNo++
	}
	gDayNo += gd2

	jDayNo := gDayNo - 79

	jNp := jDayNo / 12053
	jDayNo %= 12053

	jy = 979 + 33*jNp + 4*(jDayNo/1461)
	jDayNo %= 1461

	if jDayNo >= 366 {
		jy += (jDayNo - 1) / 365
		jDayNo = (jDayNo - 1) % 365
	}

	for i := 0; i < 11 && jDayNo >= jDaysInMonth[i]; i++ {
		jDayNo -= jDaysInMonth[i]
		jm = i + 1
	}
	jm++
	jd = jDayNo + 1
	return jy, jm, jd
}

// ShamsiToGregorian converts Jalali year, month, day to Gregorian year, month, day.
func ShamsiToGregorian(jy, jm, jd int) (gy, gm, gd int) {
	gDaysInMonth := [12]int{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	jDaysInMonth := [12]int{31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29}

	jy2 := jy - 979
	jm2 := jm - 1
	jd2 := jd - 1

	jDayNo := 365*jy2 + (jy2/33)*8 + ((jy2%33)+3)/4
	for i := 0; i < jm2; i++ {
		jDayNo += jDaysInMonth[i]
	}
	jDayNo += jd2

	gDayNo := jDayNo + 79

	gy = 1600 + 400*(gDayNo/146097)
	gDayNo %= 146097

	leap := true
	if gDayNo >= 36525 {
		gDayNo--
		gy += 100 * (gDayNo / 36524)
		gDayNo %= 36524

		if gDayNo >= 365 {
			gDayNo++
		} else {
			leap = false
		}
	}

	gy += 4 * (gDayNo / 1461)
	gDayNo %= 1461

	if gDayNo >= 366 {
		leap = false
		gDayNo--
		gy += gDayNo / 365
		gDayNo %= 365
	}

	for i := 0; gDayNo >= gDaysInMonth[i]+boolToInt(i == 1 && leap); i++ {
		gDayNo -= gDaysInMonth[i] + boolToInt(i == 1 && leap)
		gm = i + 1
	}
	gm++
	gd = gDayNo + 1
	return gy, gm, gd
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

// TimeToTehranShamsi converts a UTC time into Tehran Shamsi representation (+3:30 offset).
func TimeToTehranShamsi(t time.Time) ShamsiDate {
	tehranLoc := time.FixedZone("Asia/Tehran", 3*3600+30*60)
	tt := t.In(tehranLoc)

	jy, jm, jd := GregorianToShamsi(tt.Year(), int(tt.Month()), tt.Day())

	weekdayIdx := (int(tt.Weekday()) + 1) % 7
	weekdayName := ShamsiWeekdayNames[weekdayIdx]
	monthName := ShamsiMonthNames[jm-1]

	formatted := fmt.Sprintf("%d %s %d - ساعت %02d:%02d", jd, monthName, jy, tt.Hour(), tt.Minute())

	return ShamsiDate{
		Year:        jy,
		Month:       jm,
		Day:         jd,
		Hour:        tt.Hour(),
		Minute:      tt.Minute(),
		Second:      tt.Second(),
		MonthName:   monthName,
		WeekdayName: weekdayName,
		Formatted:   formatted,
	}
}
