# © AngelaMos | 2026
# cyber_test.exs

defmodule CertScout.CyberTest do
  use ExUnit.Case, async: true

  alias CertScout.Config
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

  test "keep?/2 is the shared gate: classifier by default, anything non-empty under --all" do
    assert Cyber.keep?("Security Engineer", %Config{})
    refute Cyber.keep?("Security Guard", %Config{})
    refute Cyber.keep?("Backend Software Engineer", %Config{})

    assert Cyber.keep?("Backend Software Engineer", %Config{include_all: true})
    refute Cyber.keep?("", %Config{include_all: true})
    refute Cyber.keep?(nil, %Config{})
  end
end
