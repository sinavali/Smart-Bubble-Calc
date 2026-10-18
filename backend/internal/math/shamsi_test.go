package math

import (
	"testing"
	"time"
)

func TestGregorianToShamsi(t *testing.T) {
	// Test known dates:
	// 2026-03-21 -> 1405-01-01 (Nowruz)
	jy, jm, jd := GregorianToShamsi(2026, 3, 21)
	if jy != 1405 || jm != 1 || jd != 1 {
		t.Errorf("expected 1405/01/01, got %04d/%02d/%02d", jy, jm, jd)
	}

	// 2026-10-19 -> 1405-07-27 (27 Mehr 1405)
	jy2, jm2, jd2 := GregorianToShamsi(2026, 10, 19)
	if jy2 != 1405 || jm2 != 7 || jd2 != 27 {
		t.Errorf("expected 1405/07/27, got %04d/%02d/%02d", jy2, jm2, jd2)
	}

	// Test reverse conversion
	gy, gm, gd := ShamsiToGregorian(1405, 7, 27)
	if gy != 2026 || gm != 10 || gd != 19 {
		t.Errorf("expected 2026/10/19, got %04d/%02d/%02d", gy, gm, gd)
	}
}

func TestTimeToTehranShamsi(t *testing.T) {
	// 2026-10-18 23:00:00 UTC = 2026-10-19 02:30:00 Tehran time (+3:30) -> 1405-07-27
	utcTime := time.Date(2026, 10, 18, 23, 0, 0, 0, time.UTC)
	shamsi := TimeToTehranShamsi(utcTime)

	if shamsi.Year != 1405 || shamsi.Month != 7 || shamsi.Day != 27 {
		t.Errorf("expected 1405/07/27 in Tehran, got %04d/%02d/%02d", shamsi.Year, shamsi.Month, shamsi.Day)
	}
	if shamsi.Hour != 2 || shamsi.Minute != 30 {
		t.Errorf("expected 02:30, got %02d:%02d", shamsi.Hour, shamsi.Minute)
	}
	if shamsi.MonthName != "مهر" {
		t.Errorf("expected مهر, got %s", shamsi.MonthName)
	}
}
