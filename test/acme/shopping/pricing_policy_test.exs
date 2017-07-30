defmodule Acme.Shopping.PricingPolicyTest do
  use Acme.DataCase

  alias Acme.Shopping.PricingPolicy
  doctest PricingPolicy.BundlePolicy
  doctest PricingPolicy.DegressivePolicy

  @valid_attrs %{name: "One for one", rule: "DefaultPolicy"}

  def default(params\\ %{}) do
    %PricingPolicy{}
    |> Map.merge(@valid_attrs)
    |> Map.merge(params)
    |> Acme.Repo.insert!
  end

  describe "changeset" do

    test "accept valid params" do

      # when
      changeset = PricingPolicy.changeset(%PricingPolicy{}, @valid_attrs)

      # then
      assert changeset.valid?
    end

    test "reject empty params" do

      # given
      params = %{}

      # when
      changeset = PricingPolicy.changeset(%PricingPolicy{}, params)

      # then
      refute changeset.valid?
    end

    test "reject with non-existent rule" do

      # when
      changeset = PricingPolicy.changeset(%PricingPolicy{}, %{@valid_attrs | rule: "UnexistingPolicy"})

      # then
      refute changeset.valid?
      assert changeset.errors[:rule] == {"Not defined in codebase", []}
    end

  end

end