<schema xmlns="http://purl.oclc.org/dsdl/schematron"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  queryBinding="xslt1">

  <let name="module-code" value="'example'" />

  <!-- Set $diagnostic to true() if every rule should report
       when firing -->
  <let name="diagnostic" value="false()"/>

  <!-- Specific error conditions. -->
  <pattern id="ERROR">
    <rule id="baz" context="baz">
      <assert role="ERROR_FOO"
	      test="count(foo) = count(bar)">
Number of 'foo' and 'bar' should be equal.</assert>
      <report role="ERROR_BAR"
	      test="count(bar) > 5">
baz should contain no more than 5 bar.</report>
      </rule>
    </pattern>
  </schema>
