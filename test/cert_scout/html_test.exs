# © AngelaMos | 2026
# html_test.exs

defmodule CertScout.HtmlTest do
  use ExUnit.Case, async: true

  alias CertScout.Html

  test "strips tags and collapses whitespace" do
    assert Html.to_text("<p>Hello   <b>world</b></p>") == "Hello world"
  end

  test "unescapes entity-encoded markup before parsing" do
    encoded = "&lt;p&gt;Requires CISSP &amp; Security+&lt;/p&gt;"
    assert Html.to_text(encoded) == "Requires CISSP & Security+"
  end

  test "decodes numeric entities" do
    assert Html.to_text("Caf&#233; &#x26; co") == "Café & co"
  end

  test "drops invalid surrogate code points instead of raising" do
    assert Html.to_text("alpha &#xD800; omega") == "alpha omega"
  end

  test "handles nil and empty input" do
    assert Html.to_text(nil) == ""
    assert Html.to_text("") == ""
  end
end
