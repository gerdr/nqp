#! nqp

# sprintf. This file will be moved to t/hll once it handles everything that parrot's sprintf can.

my $die_message := 'unset';

sub dies_ok(&callable, $description) {
    &callable();
    ok(0, $description);
    return '';

    CATCH {
        ok(1, $description);
        $die_message := $_;
    }
}

sub is($actual, $expected, $description) {
    my $they_are_equal := $actual eq $expected;
    ok($they_are_equal, $description);
    unless $they_are_equal {
        say("#   Actual value: $actual");
        say("# Expected value: $expected");
    }
}

plan(154);

is(nqp::sprintf('Walter Bishop', []), 'Walter Bishop', 'no directives' );

is(nqp::sprintf('Peter %s', ['Bishop']), 'Peter Bishop', 'one %s directive' );
is(nqp::sprintf('%s %s', ['William', 'Bell']), 'William Bell', 'two %s directives' );

dies_ok({ nqp::sprintf('%s %s', ['Dr.', 'William', 'Bell']) }, 'arguments > directives' );
is($die_message, 'Too few directives: found 2, fewer than the 3 arguments after the format string',
    'arguments > directives error message' );

dies_ok({ nqp::sprintf('%s %s %s', ['Olivia', 'Dunham']) }, 'directives > arguments' );
is($die_message, 'Too many directives: found 3, but only 2 arguments after the format string',
    'directives > arguments error message' );

dies_ok({ nqp::sprintf('%s %s', []) }, 'directives > 0 arguments' );
is($die_message, 'Too many directives: found 2, but no arguments after the format string',
    'directives > 0 arguments error message' );

is(nqp::sprintf('%% %% %%', []), '% % %', '%% escape' );

dies_ok({ nqp::sprintf('%a', 'Science') }, 'unknown directive' );
is($die_message, "'a' is not valid in sprintf format sequence '%a'",
    'unknown directive error message' );

is(nqp::sprintf('<%6s>', [12]), '<    12>', 'right-justified %s with space padding');
is(nqp::sprintf('<%6%>', []), '<     %>', 'right-justified %% with space padding');
is(nqp::sprintf('<%06s>', ['hi']), '<0000hi>', 'right-justified %s with 0-padding');
is(nqp::sprintf('<%06%>', []), '<00000%>', 'right-justified %% with 0-padding');

is(nqp::sprintf('<%*s>', [6, 12]), '<    12>', 'right-justified %s with space padding, star-specified');
is(nqp::sprintf('<%0*s>', [6, 'a']), '<00000a>', 'right-justified %s with 0-padding, star-specified');
is(nqp::sprintf('<%*%>', [6]), '<     %>', 'right-justified %% with space padding, star-specified');
is(nqp::sprintf('<%0*%>', [5]), '<0000%>', 'right-justified %% with 0-padding, star-specified');

is(nqp::sprintf('<%2s>', ['long']), '<long>', '%s string longer than specified size');

is(nqp::sprintf('<%d>', [1]), '<1>', '%d without size or precision');
is(nqp::sprintf('<%d>', ["lol, I am a string"]), '<0>', '%d on a non-number');
is(nqp::sprintf('<%d>', [42.18]), '<42>', '%d on a float');
is(nqp::sprintf('<%d>', [-18.42]), '<-18>', '%d on a negative float');
is(nqp::sprintf('<%03d>', [1]), '<001>', '%d on decimal with 0-padding');
is(nqp::sprintf('<%03d>', [-11]), '<-11>', '%d on negative decimal with 0-padding (but nothing to pad)');
is(nqp::sprintf('<%04d>', [-1]), '<-001>', '%d on negative decimal with 0-padding');
is(nqp::sprintf('<%+4d>', [42]), '< +42>', '%d on a positive decimal, space-padding with plus sign');
is(nqp::sprintf('<%+04d>', [42]), '<+042>', '%d on a positive decimal, zero-padding with plus sign');

is(nqp::sprintf('%c', [97]), 'a', '%c directive');
is(nqp::sprintf('%10c', [65]), '         A', '%c directive with space padding');
is(nqp::sprintf('%c%c%c', [187, 246, 171]), '»ö«', '%c directive with non-asci codepoints');
is(nqp::sprintf('%06c', [97]), '00000a', '%c directive with 0-padding');

is(nqp::sprintf('%o', [12]), '14', 'simple %o');
is(nqp::sprintf('%o', [22.01]), '26', 'decimal %o');
is(nqp::sprintf('%06o', [127]), '000177', '%o with 0-padding');
is(nqp::sprintf('%#6o', [127]), '  0177', '%o with space-padding and leading 0');

is(nqp::sprintf('%x', [0]), '0', 'simple %x');
is(nqp::sprintf('%x', [12]), 'c', 'simple %x');
is(nqp::sprintf('%x', [22.01]), '16', 'decimal %x');
is(nqp::sprintf('%X', [12]), 'C', 'simple %X');
is(nqp::sprintf('%#X', [12]), '0XC', "%X, '0X' prepended");
is(nqp::sprintf('%#x', [12]), '0xc', "%x ,'0x prepended'");
is(nqp::sprintf('%#5x', [12]), '  0xc', '%x, hash and width');
is(nqp::sprintf('%#5.2x', [12]), ' 0x0c', '%x, hash, width and precision');
is(nqp::sprintf('%5.2x', [12]), '   0c', '%x, no hash, but width and precision');
is(nqp::sprintf('%05x', [12]), '0000c', '%x with zero-padding');
is(nqp::sprintf('%0*x', [4, 12]), '000c', '%x with zero-padding, star-specified');

is(nqp::sprintf('%u', [12]), '12', 'simple %u');
is(nqp::sprintf('%u', [22.01]), '22', 'decimal %u');
is(nqp::sprintf("%u", [2**32]), "4294967296", "max uint32 to %u");

is(nqp::sprintf('%B', [2**32-1]), '11111111111111111111111111111111', 'simple %B');
is(nqp::sprintf('%+B', [2**32-1]), '11111111111111111111111111111111', 'simple %B with plus sign');
is(nqp::sprintf('%#B', [2**32-1]), '0B11111111111111111111111111111111', '%B with 0B prefixed');
is(nqp::sprintf('%b', [2**32-1]), '11111111111111111111111111111111', 'simple %b');
is(nqp::sprintf('%+b', [2**32-1]), '11111111111111111111111111111111', 'simple %b with plus sign');
is(nqp::sprintf('%#b', [2**32-1]), '0b11111111111111111111111111111111', '%b with 0b prefixed');
is(nqp::sprintf('%34b', [2**32-1]), '  11111111111111111111111111111111', '%b right justified using space chars');
is(nqp::sprintf('%034b', [2**32-1]), '0011111111111111111111111111111111', '%b right justified, 0-padding');
is(nqp::sprintf('%-34b', [2**32-1]), '11111111111111111111111111111111  ', '%b left justified using space chars');
is(nqp::sprintf('%-034b', [2**32-1]), '11111111111111111111111111111111  ', '%b left justified, 0-padding');
is(nqp::sprintf('%6b', [12]), '  1100', 'simple %b, padded');
is(nqp::sprintf('%6.5b', [12]), ' 01100', '%b, right justified and precision');
is(nqp::sprintf('%-6.5b', [12]), '01100 ', '%b, left justified and precision');
is(nqp::sprintf('%+6.5b', [12]), ' 01100', '%b, right justified and precision, plus sign');
is(nqp::sprintf('% 6.5b', [12]), ' 01100', '%b, right justified and precision, space char');
is(nqp::sprintf('%06.5b', [12]), ' 01100', '%b, 0 flag with precision: no effect');
is(nqp::sprintf('%.5b', [12]), '01100', '%b with precision but no width');
is(nqp::sprintf('%.0b', [0]), '', '%b, precision zero, no value');
is(nqp::sprintf('%+.0b', [0]), '', '%b, precision zero, plus sign, no value');
is(nqp::sprintf('% .0b', [0]), '', '%b, precision zero, space char, no value');
is(nqp::sprintf('%-.0b', [0]), '', '%b, precision zero, minus, no value');
is(nqp::sprintf('%#.0b', [0]), '', '%b, precision zero, hash, no value');
is(nqp::sprintf('%#3.0b', [0]), '   ', '%b, width but zero precision');
is(nqp::sprintf('%#3.1b', [0]), '  0', '%b, width and precision but zero value');
is(nqp::sprintf('%#3.2b', [0]), ' 00', '%b, width and precision but zero value');
is(nqp::sprintf('%#3.3b', [0]), '000', '%b, width and precision but zero value');
is(nqp::sprintf('%#3.4b', [0]), '0000', '%b, width and precision but zero value, overlong');
is(nqp::sprintf('%.0b', [1]), '1', '%b, precision zero and value');
is(nqp::sprintf('%+.0b', [1]), '1', '%b, precision zero, plus sign and value');
is(nqp::sprintf('% .0b', [1]), '1', '%b, precision zero, space char and value');
is(nqp::sprintf('%-.0b', [1]), '1', '%b, precision zero, hash and value');
is(nqp::sprintf('%#.0b', [1]), '0b1', '%b, width, zero precision, no value');
is(nqp::sprintf('%#3.0b', [1]), '0b1', '%b, width, zero precision but value');
is(nqp::sprintf('%#3.1b', [1]), '0b1', '%b, width and precision and value');
is(nqp::sprintf('%#3.2b', [1]), '0b01', '%b, width and precision and value');
is(nqp::sprintf('%#3.3b', [1]), '0b001', '%b, width and precision and value');
is(nqp::sprintf('%#3.4b', [1]), '0b0001', '%b, width and precision and value');
is(nqp::sprintf('%#b', [0]), '0', 'simple %b with zero value');

is(nqp::sprintf('%5.2e', [0.0]),    '0.00e+00',    '5.2 %e');
is(nqp::sprintf('%5.2e', [3.1415]),    '3.14e+00',    '5.2 %e');
is(nqp::sprintf('%5.2E', [3.1415]),    '3.14E+00',    '5.2 %E');
is(nqp::sprintf('%20.2e', [3.1415]),   '            3.14e+00',    '20.2 %e');
is(nqp::sprintf('%20.2E', [3.1415]),   '            3.14E+00',    '20.2 %E');
is(nqp::sprintf('%20.2e', [-3.1415]),  '           -3.14e+00',    'negative 20.2 %e');
is(nqp::sprintf('%20.2E', [-3.1415]),  '           -3.14E+00',    'negative 20.2 %E');
is(nqp::sprintf('%020.2e', [3.1415]),  '0000000000003.14e+00',    '020.2 %e');
is(nqp::sprintf('%020.2E', [3.1415]),  '0000000000003.14E+00',    '020.2 %E');
is(nqp::sprintf('%020.2e', [-3.1415]), '-000000000003.14e+00',    'negative 020.2 %e');
is(nqp::sprintf('%020.2E', [-3.1415]), '-000000000003.14E+00',    'negative 020.2 %E');
is(nqp::sprintf('%e', [2.718281828459]), nqp::sprintf('%.6e', [2.718281828459]), '%e defaults to .6');
is(nqp::sprintf('<%7.3e>', [3.1415e20]), '<3.142e+20>', '%e handles big numbers');
is(nqp::sprintf('<%7.3e>', [-3.1415e20]), '<-3.142e+20>', '%e handles big negative numbers');
is(nqp::sprintf('<%7.3e>', [3.1415e-20]), '<3.142e-20>', '%e handles small numbers');
is(nqp::sprintf('<%7.3e>', [-3.1415e-20]), '<-3.142e-20>', '%e handles small negative numbers');
is(nqp::sprintf('<%7.3e>', [3e20]), '<3.000e+20>', '%e fills up to precision');

is(nqp::sprintf('%5.2f', [3.1415]),    ' 3.14',    '5.2 %f');
is(nqp::sprintf('%5.2F', [3.1415]),    ' 3.14',    '5.2 %F');
is(nqp::sprintf('%20.2f', [3.1415]),   '                3.14',    '20.2 %f');
is(nqp::sprintf('%20.2F', [3.1415]),   '                3.14',    '20.2 %F');
is(nqp::sprintf('%20.2f', [-3.1415]),  '               -3.14',    'negative 20.2 %f');
is(nqp::sprintf('%20.2F', [-3.1415]),  '               -3.14',    'negative 20.2 %F');
is(nqp::sprintf('%020.2f', [3.1415]),  '00000000000000003.14',    '020.2 %f');
is(nqp::sprintf('%020.2F', [3.1415]),  '00000000000000003.14',    '020.2 %F');
is(nqp::sprintf('%020.2f', [-3.1415]), '-0000000000000003.14',    'negative 020.2 %f');
is(nqp::sprintf('%020.2F', [-3.1415]), '-0000000000000003.14',    'negative 020.2 %F');
is(nqp::sprintf('%f', [2.718281828459]), nqp::sprintf('%.6f', [2.718281828459]), '%f defaults to .6');
is(nqp::sprintf('<%7.3f>', [0]), '<  0.000>', '%f fills up to precision');
is(nqp::sprintf('<%7.3f>', [0.1]), '<  0.100>', '%f fills up to precision');
is(nqp::sprintf('<%7.3f>', [3.1]), '<  3.100>', '%f fills up to precision');
is(nqp::sprintf('<%7.3f>', [3.1415e20]), '<314150000000000000000.000>', '%f handles big numbers');
is(nqp::sprintf('<%7.3f>', [-3.1415e20]), '<-314150000000000000000.000>', '%f handles big negative numbers');
is(nqp::sprintf('<%7.3f>', [3.1415e-2]), '<  0.031>', '%f handles small numbers');
is(nqp::sprintf('<%7.3f>', [-3.1415e-2]), '< -0.031>', '%f handles small negative numbers');

is(nqp::sprintf('%5.2g', [3.1415]),    '  3.1',    '5.2 %g');
is(nqp::sprintf('%5.2G', [3.1415]),    '  3.1',    '5.2 %G');
is(nqp::sprintf('%20.2g', [3.1415]),   '                 3.1',    '20.2 %g');
is(nqp::sprintf('%20.2G', [3.1415]),   '                 3.1',    '20.2 %G');
is(nqp::sprintf('%20.2g', [-3.1415]),  '                -3.1',    'negative 20.2 %g');
is(nqp::sprintf('%20.2G', [-3.1415]),  '                -3.1',    'negative 20.2 %G');
is(nqp::sprintf('%020.2g', [3.1415]),  '000000000000000003.1',    '020.2 %g');
is(nqp::sprintf('%020.2G', [3.1415]),  '000000000000000003.1',    '020.2 %G');
is(nqp::sprintf('%020.2g', [-3.1415]), '-00000000000000003.1',    'negative 020.2 %g');
is(nqp::sprintf('%020.2G', [-3.1415]), '-00000000000000003.1',    'negative 020.2 %G');
is(nqp::sprintf('%g', [2.718281828459]), nqp::sprintf('%.6g', [2.718281828459]), '%g defaults to precision .6');
is(nqp::sprintf('<%7.3g>', [0]), '<  0.000>', '%g fills up to precision');
is(nqp::sprintf('<%7.3g>', [0.1]), '<  0.100>', '%g fills up to precision');

is(nqp::sprintf('%5.2g', [3.1415e20]),    '3.1e+20',    '5.2 %g');
is(nqp::sprintf('%5.2G', [3.1415e20]),    '3.1E+20',    '5.2 %G');
is(nqp::sprintf('%20.2g', [3.1415e20]),   '             3.1e+20',    '20.2 %g');
is(nqp::sprintf('%20.2G', [3.1415e20]),   '             3.1E+20',    '20.2 %G');
is(nqp::sprintf('%20.2g', [-3.1415e20]),  '            -3.1e+20',    'negative 20.2 %g');
is(nqp::sprintf('%20.2G', [-3.1415e20]),  '            -3.1E+20',    'negative 20.2 %G');
is(nqp::sprintf('%20.2g', [3.1415e-20]),  '             3.1e-20',    '20.2 %g');
is(nqp::sprintf('%20.2G', [3.1415e-20]),  '             3.1E-20',    '20.2 %G');
is(nqp::sprintf('%20.2g', [-3.1415e-20]), '            -3.1e-20',    'negative 20.2 %g');
is(nqp::sprintf('%20.2G', [-3.1415e-20]), '            -3.1E-20',    'negative 20.2 %G');
is(nqp::sprintf('%020.2g', [3.1415e20]),  '00000000000003.1e+20',    '020.2 %g');
is(nqp::sprintf('%020.2G', [3.1415e20]),  '00000000000003.1E+20',    '020.2 %G');
is(nqp::sprintf('%020.2g', [-3.1415e20]), '-0000000000003.1e+20',    'negative 020.2 %g');
is(nqp::sprintf('%020.2G', [-3.1415e20]), '-0000000000003.1E+20',    'negative 020.2 %G');
is(nqp::sprintf('<%7.3g>', [3e20]), '<3e+20>', '%g does not fill up to precision');
is(nqp::sprintf('<%7.3g>', [3.1e20]), '<3.1e+20>', '%g does not fill up to precision');
