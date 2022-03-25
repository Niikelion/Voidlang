:: @echo off
echo %1
type "%1"
:: type %1 | grun Void1 input 2>&1 | grep "^line" -q -c
for /f %%i in ('type Test.bat') do set passed=%%i

echo %passed%

if passed GEQ 1 (
    echo "a"
) ELSE (
    echo "b"
)