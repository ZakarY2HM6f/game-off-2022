pub fn getCursedValue(original: f64, curse: f64, rate: f64) f64 {
    return @max(original - curse * rate, original * 0.1);
}
