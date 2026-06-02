# © AngelaMos | 2026
# cyber_test.exs

defmodule CertScout.CyberTest do
  use ExUnit.Case, async: true

  alias CertScout.Cyber

  test "recognizes cybersecurity roles" do
    assert Cyber.match?("Security Engineer")
    assert Cyber.match?("Senior Penetration Tester")
    assert Cyber.match?("SOC Analyst II")
    assert Cyber.match?("Director, Information Security")
    assert Cyber.match?("Cloud Security Architect")
    assert Cyber.match?("Threat Detection Engineer")
  end

  test "rejects unrelated and physical-security roles" do
    refute Cyber.match?("Backend Software Engineer")
    refute Cyber.match?("Security Officer")
    refute Cyber.match?("Security Guard")
    refute Cyber.match?("Trust and Safety Specialist")
    refute Cyber.match?("Product Manager")
  end
end
