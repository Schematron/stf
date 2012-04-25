* Version: 0.1
* Author: Mentea
* Date: 24 November 2011

# Schematron Testing Framework (stf)

A test suite for schematron ordinarily contains many
instances of contexts where a Schematron assert is expected
to fail or a report to be successful.  For any reasonably
sized test suite, there will be so many that it becomes
impossible to separate the expected results from the
unexpected.

stf is a XProc pipeline that uses a PI in the test document that
indicates the expected 'assert's and 'report's to winnow out the
expected result and report just the unexpected.


## Prerequisites

Requires Ant and Calabash.  Calabash (as used here) requires Saxon.  All three require Java.

## Usage

1. Set the properties in `properties.xml` to match your local setup.

2. Write the tests, including a `<?stf?>` processing instruction in each.

    One practice is to use a 'tests' directory containing a 'go'
    subdirectory for tests that are expected to have no Schematron
    `assert` or `report` errors and a `nogo` subdirectory for tests
    that are expected to have errors, but you can organise them any
    way you like.

3. Run Ant

    You can run the `test.schematron` from `build.xml` directly:
    
        ant -f /path/to/stf/build.xml test.schemtron
	
    or you can import the stf `build.xml` into your local `build.xml`:
    
        <property name="stf.dir" location="/path/to/stf" />
        <import file="${stf.dir}/build.xml" />

    and run the `test.schematron` target, or you can import the stf
    `build.xml` and use the `<test.schematron />` macro in your local
    `build.xml`.

## Ant Properties

* `${schematron}`

    Schematron file to test.

* `${tests.dir}`

    Directory containing test files.
    
* `${calabash.jar}`

    Location of Calabash jar.

* `${saxon.jar}`

    Location of Saxon 9.2 (or later) jar.

* `${resolver.jar}`

    Location of XML catalog resolver library.
    
* `${resolver.class}`

    Class name of XML catalog resolver.  Default is
    `org.apache.xml.resolver.tools.CatalogResolver`.
    
## &lt;?stf?> Processing Instruction

The format of the PI is:

    <?stf ( '#NONE' | ROLE ':' COUNT ( \s+ ROLE ':' COUNT )* ) ?>

where:

* `stf`

    PI target
    
* `#NONE`

    No `assert` or `report` expected.  Use with
'go' tests that should not have any asserts
or reports.  If running Schematron on the test
produces any asserts or reports, they are
reported as an error.

* _ROLE_

    Token corresponding to `@role` value of an
`assert` or a `report` in the Schematron.
Schematron allows @role to be an arbitrary
string, but restricting it to a single token
makes it easier to deal with the PI using
regular expressions rather than having to
parse roles that may contain spaces.

* _COUNT_

    Integer number of expected occurrences of
failed asserts or successful reports with
@role value matching _ROLE_.

    A mismatch between the expected and actual
count is reported as an error.

    A _ROLE_ starting with # does not have its
count checked.


## Examples

    <?stf ERROR_FOO:2 ERROR_BAR:1 ?>

An `assert` or `report` with `role="ERROR_FOO"` is expected twice in
the SVRL from the test document, and either with `role="ERROR_BAR"` is
expected once.


    <?stf ERROR_FOO:2 #ERROR_BAR:1 ?>

An `assert` or `report` with `role="ERROR_FOO"` is
expected twice in the SVRL, and no `assert` or `report` with
`role="ERROR_BAR"` is expected since `#` precedes `ERROR_BAR`.


    <?stf #NONE ?>

No `assert` or `report` are expected for the current document.



## XProc Processor

The pipeline currently depends on Calabash extensions.

The version of Calabash used in testing depended on Saxon 9.2 or later.

## Running (Not Testing) Schematron

Ant build file also includes `schematron` macro and `run.schematron`
target to make it easy to run Schematron on real files once you're
sure it works on your tests.

## License

Licensed under the terms of a BSD license.  See the file `COPYING` for
details.

