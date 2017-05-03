service HelloSvc {
    string hello_func(),
}

service TimesTwo {
    i64 dbl(1: i64 val),
}