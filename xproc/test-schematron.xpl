<?xml version="1.0" encoding="UTF-8"?>
<!-- ============================================================= -->
<!--  MODULE:    Schematron testing XProc pipeline                 -->
<!--  VERSION:   1.0                                               -->
<!--  DATE:      February 2011                                     -->
<!--                                                               -->
<!-- ============================================================= -->

<!-- ============================================================= -->
<!-- SYSTEM:     Schematron Testing Framework (stf)                -->
<!--                                                               -->
<!-- PURPOSE:    Runs Schematron on test files and checks that     -->
<!--             result contains only the expected asserts and     -->
<!--             reports.                                          -->
<!--                                                               -->
<!-- CONTAINS:                                                     -->
<!--             1. XProc pipeline for running Schematron on test  -->
<!--                files.                                         -->
<!--             2. Embedded XSLT2 stylesheet for checking result. -->
<!--                                                               -->
<!-- CREATED FOR:                                                  -->
<!--             Mentea                                            -->
<!--             http://www.mentea.net/                            -->
<!--                                                               -->
<!-- ORIGINAL CREATION DATE:                                       -->
<!--             February 2011                                     -->
<!--                                                               -->
<!-- CREATED BY: Mentea (tkg)                                      -->
<!--                                                               -->
<!-- ============================================================= -->
<!-- ============================================================= -->
<!--              VERSION HISTORY                                  -->
<!-- ============================================================= -->
<!--
    1.  ORIGINAL VERSION                                 tkg 20110210
-->

<!-- ============================================================= -->
<!--                    DESIGN CONSIDERATIONS                      -->
<!-- ============================================================= -->
<!-- A test suite for schematron ordinarily contains many
     instances of contexts where a Schematron assert is expected
     to fail or a report to be successful.  For any reasonably
     sized test suite, there will be so many that it becomes
     impossible to separate the expected results from the
     unexpected.

     This XProc pipeline uses a PI in the test document that
     indicates the expected 'assert's and 'report's to winnow out the
     expected result and report just the unexpected.

     The format of the PI is:

     <?stf ( '#NONE' | ROLE ':' COUNT ( \s+ ROLE ':' COUNT )* ) ?>

     where:

       'stf'      PI target

       '#NONE'    No 'assert' or 'report' expected.  Use with
                  'go' tests that should not have any asserts
                  or reports.  If running Schematron on the test
                  produces any asserts or reports, they are
                  reported as an error.

       ROLE       Token corresponding to @role value of an
                  assert or a report in the Schematron.
                  Schematron allows @role to be an arbitrary
                  string, but restricting it to a single token
                  makes it easier to deal with the PI using
                  regular expressions rather than having to
                  parse roles that may contain spaces.

       COUNT      Integer number of expected occurrences of
                  failed asserts or successful reports with
                  @role value matching ROLE.

                  A mismatch between the expected and actual
                  count is reported as an error.

                  A ROLE starting with '#' does not have its
                  count checked.

    Examples:

       <?stf ERROR_FOO:2 ERROR_BAR:1 ?>

    An 'assert' or 'report' with 'role="ERROR_FOO"' is
    expected twice in the SVRL, and either with
    'role="ERROR_BAR"' is expected once.


       <?stf ERROR_FOO:2 #ERROR_BAR:1 ?>

    An 'assert' or 'report' with 'role="ERROR_FOO"' is
    expected twice in the SVRL, and no 'assert' or 'report' with
    'role="ERROR_BAR"' is expected since '#' precedes 'ERROR_BAR'.


       <?stf #NONE ?>

    No 'assert' or 'report' are expecetd.



XPROC PROCESSOR

    This pipeline depends on Calabash extensions.

                                                                   -->
<!-- ============================================================= -->

<!-- ============================================================= -->
<!--                    XPROC PIPELINE INVOCATION                  -->
<!-- ============================================================= -->

<p:declare-step
    xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
    name="test-schematron"
    version="1.0">


<!-- ============================================================= -->
<!--                    PIPELINE OPTIONS                           -->
<!-- ============================================================= -->

<!-- Path to test directory.  All grandchildren '.xml' files are
     run. -->
<p:option name="path" required="true"/>
<!-- Location of Schematron to be tested. -->
<p:option name="schematron" required="true"/>


<!-- ============================================================= -->
<!--                    PIPELINE OUTPUT                            -->
<!-- ============================================================= -->

<p:output port="result" sequence="true"/>


<!-- ============================================================= -->
<!--                    PIPELINE STEPS                             -->
<!-- ============================================================= -->

<!-- Load $schematron for later piping to
     <p:validate-with-schematron>. -->
<p:load name="load-schematron">
  <p:with-option
      name="href"
      select="$schematron"/>
</p:load>

<!-- Get list of files and directories in $path. -->
<p:directory-list>
    <p:with-option name="path" select="$path">
        <p:empty/>
    </p:with-option>
</p:directory-list>
<!-- Repeat for children of $path. -->
<p:for-each name="directoryloop">
    <p:output port="result" sequence="true"/>
    <p:iteration-source
        select="/c:directory/c:directory"/>
    <p:variable
        name="dirpath"
        select="p:resolve-uri(concat(c:directory/@name,
                                     '/'),
                               p:base-uri(c:directory))"/>
    <p:directory-list>
        <p:with-option
            name="path"
            select="$dirpath"/>
    </p:directory-list>
    <p:make-absolute-uris
        match="c:file/@name">
        <p:with-option
            name="base-uri"
            select="$dirpath"/>
    </p:make-absolute-uris>
    <!-- Run Schematron on each file. -->
    <p:for-each name="fileloop">
        <p:iteration-source
            select="/c:directory/c:file[ends-with(@name,
                                                  '.xml')]"/>
        <p:variable
            name="file"
            select="/c:file/@name"/>
        <p:load name="file">
            <p:with-option
                name="href"
                select="$file"/>
        </p:load>
        <!-- Don't die if an assert fails: many asserts
             will fail when running tests on the Schematron. -->
        <p:validate-with-schematron
            name="schematron"
            assert-valid="false">
            <p:input port="parameters">
                <p:empty/>
            </p:input>
            <p:input port="schema">
                <p:pipe step="load-schematron" port="result"/>
            </p:input>
        </p:validate-with-schematron>
        <!-- Wrap test and Schematron output into one
             document. -->
        <p:pack wrapper="wrap">
            <p:input port="alternate">
                <p:pipe step="schematron" port="report"/>
            </p:input>
        </p:pack>
        <!-- Run embedded XSLT on source+output. -->
        <p:xslt>
            <p:input port="stylesheet">
                <p:inline>
                    <xsl:stylesheet
                        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                        xmlns:xs="http://www.w3.org/2001/XMLSchema"
                        xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                        xmlns:cx="http://xmlcalabash.com/ns/extensions"
                        xmlns:c="http://www.w3.org/ns/xproc-step"
                        version="2.0"
                        exclude-result-prefixes="xs svrl cx c">
                        <xsl:strip-space elements="*"/>
                        <xsl:output method="xml" />
                        
                        <!-- Save the value of the PI. -->
                        <xsl:variable
                            name="expected"
                            select="normalize-space(wrap/processing-instruction('stf')[1])"
                            as="xs:string?"/>

                        <!-- Put a wrapper around result
                             and report test file location. -->
                        <xsl:template match="wrap">
                            <result>
                                <file>
                                <xsl:value-of
                                    select="svrl:schematron-output/svrl:active-pattern[1]/@document"
                                    />
                                </file>
                                <xsl:apply-templates />
                            </result>
                        </xsl:template>

                        <!-- Process Schematron result. -->
                        <xsl:template match="svrl:schematron-output">
                            <!-- Will lose track of current
                                 node in some of the xsl:for-each. -->
                            <xsl:variable
                                name="dot"
                                select="." />
                            <xsl:choose>
                                <xsl:when
                                    test="empty($expected) or $expected = '#NONE'">
                                    <xsl:if
                                        test="empty($expected)">
                                        <message>No 'stf' processing instruction.</message>
                                    </xsl:if>
                                    <xsl:if
                                        test="exists(svrl:successful-report | svrl:failed-assert)">
                                        <error>
                                            <xsl:text>Should be no reports or asserts.</xsl:text>
                                            <xsl:for-each
                                                select="distinct-values($dot/(svrl:successful-report|svrl:failed-assert)/@role)">
                                                <xsl:text>&#xA;Unexpected: </xsl:text>
                                                <xsl:value-of
                                                    select="." />
                                                <xsl:text>:</xsl:text>
                                                <xsl:value-of
                                                    select="count($dot/(svrl:successful-report|svrl:failed-assert)[@role eq current()])" />
                                            </xsl:for-each>
                                        </error>
                                    </xsl:if>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each
                                        select="tokenize(normalize-space($expected), ' ')">
                                        <xsl:variable
                                            name="id"
                                            select="tokenize(., ':')[1]"/>
                                        <xsl:variable
                                            name="count"
                                            select="if (tokenize(., ':')[2] ne '')
                                                       then xs:integer(tokenize(., ':')[2])
                                                       else 1"
                                            as="xs:integer" />
                                        <xsl:if
                                            test="not(starts-with($id, '#')) and
                                                  count($dot/(svrl:successful-report|svrl:failed-assert)[lower-case(@role) eq lower-case($id)]) != $count">
                                            <error>
                                                <xsl:text>Should be </xsl:text>
                                                <xsl:value-of
                                                    select="$count" />
                                                <xsl:text> reports or asserts for </xsl:text>
                                                <xsl:value-of
                                                    select="$id" />
                                                <xsl:text>.  Found </xsl:text>
                                                <xsl:value-of
                                                    select="count($dot/(svrl:successful-report|svrl:failed-assert)[lower-case(@role) eq lower-case($id)])" />
                                                <xsl:text>.</xsl:text>
                                            </error>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <xsl:variable
                                        name="ids"
                                        select="for $token in tokenize($expected, ' ')
                                                  return lower-case(tokenize($token, ':')[1])"/>
                                    <xsl:for-each
                                        select="distinct-values($dot/(svrl:successful-report|svrl:failed-assert)[not(lower-case(@role) = $ids)]/@role)">
                                        <error>
                                            <xsl:text>Unexpected: </xsl:text>
                                            <xsl:value-of
                                                select="." />
                                            <xsl:text>:</xsl:text>
                                            <xsl:value-of
                                                select="count($dot/(svrl:successful-report|svrl:failed-assert)[@role eq current()])" /></error>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:template>
                        
                        <!-- Drop any text from the Schematron result. -->
                        <xsl:template match="text()" />
                    </xsl:stylesheet>
                </p:inline>
            </p:input>
            <p:with-param name="path" select="$path">
                <p:empty/>
            </p:with-param>
            <p:with-option name="version" select="'2.0'"/>
        </p:xslt>
    </p:for-each>
</p:for-each>
<!-- Drop any results that don't have any <error>. -->
<p:split-sequence test="result[exists(error)]"/>
<!-- Wrap the result in <errors> to make well-formed XML. -->
<p:wrap-sequence wrapper="errors" />

</p:declare-step>

<!-- ============================================================= -->
<!--                    END OF 'test-schematron.xpl'               -->
<!-- ============================================================= -->
