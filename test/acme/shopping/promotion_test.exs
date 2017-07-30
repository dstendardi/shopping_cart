defmodule Acme.Shopping.PromotionTest do
  use Acme.DataCase

  alias Acme.Shopping.{Promotion, ProductTest, PricingPolicyTest}

  describe "changeset" do

    test "accept valid params" do

      # given
      params = %{product_id: ProductTest.default().id, pricing_policy_id: PricingPolicyTest.default().id}

      # when
      changeset = Promotion.changeset(%Promotion{}, params)

      # then
      assert changeset.valid?
    end

    test "reject with empty params" do

      # given
      params = %{}

      # when
      changeset = Promotion.changeset(%Promotion{}, params)

      # then
      refute changeset.valid?
      assert changeset.errors[:product_id] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:pricing_policy_id] == {"can't be blank", [validation: :required]}

    end

    test "reject non-existent pricing policy" do

      # given
      params = %{
        product_id: ProductTest.default().id,
        pricing_policy_id: Ecto.UUID.generate()
      }

      # when
      {:error, changeset} = %Promotion{} |> Promotion.changeset(params) |> Acme.Repo.insert

      # then
      refute changeset.valid?
      assert changeset.errors[:pricing_policy_id] == {"does not exist", []}
    end

    test "reject non-existent product" do

      # given
      params = %{
        product_id: Ecto.UUID.generate(),
        pricing_policy_id: PricingPolicyTest.default().id
      }

      # when
      {:error, changeset} = %Promotion{} |> Promotion.changeset(params) |> Acme.Repo.insert

      # then
      refute changeset.valid?
      assert changeset.errors[:product_id] == {"does not exist", []}
    end
  end
end