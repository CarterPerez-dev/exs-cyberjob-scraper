# © AngelaMos | 2026
# certification_test.exs

defmodule CertScout.CertificationTest do
  use ExUnit.Case, async: true

  alias CertScout.Certification

  test "matches on word boundaries, not substrings" do
    cissp = Certification.new(slug: "cissp", name: "CISSP", aliases: ["CISSP"])

    assert Certification.mentioned?(cissp, "CISSP required")
    assert Certification.mentioned?(cissp, "certifications: cissp, cism")
    refute Certification.mentioned?(cissp, "CISSPISH nonsense")
    refute Certification.mentioned?(cissp, "no certs here")
  end

  test "handles plus-suffixed certifications" do
    sec = Certification.new(slug: "secplus", name: "Security+", aliases: ["Security+", "Sec+"])

    assert Certification.mentioned?(sec, "CompTIA Security+ is required")
    assert Certification.mentioned?(sec, "Sec+ or equivalent")
    refute Certification.mentioned?(sec, "Securityplus is not the same")
  end

  test "matches any alias in the list" do
    ceh = Certification.new(slug: "ceh", name: "CEH", aliases: ["CEH", "Certified Ethical Hacker"])

    assert Certification.mentioned?(ceh, "We value a Certified Ethical Hacker")
    assert Certification.mentioned?(ceh, "CEH a plus")
    refute Certification.mentioned?(ceh, "cache invalidation")
  end
end
