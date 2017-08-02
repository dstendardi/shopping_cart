defmodule Acme.Shopping.ProductTest do
  use Acme.DataCase

  alias Acme.Shopping.Product
  import Money.Sigils

  @valid_attrs %{name: "t-shirt", price: ~M[20_00] }

  def default() do
    %Product{}
    |> Map.merge(@valid_attrs)
    |> Acme.Repo.insert!
  end

  describe "changeset" do

    test "accept valid params" do

      # when
      changeset = Product.changeset(%Product{}, @valid_attrs)

      # then
      assert changeset.valid?
    end

    test "reject with empty params" do

      # given
      params = %{}

      # when
      changeset = Product.changeset(%Product{}, params)

      # then
      refute changeset.valid?
      assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:price] == {"can't be blank", [validation: :required]}
    end

    test "reject a price equals to zero" do

      # given
      params = %{@valid_attrs | price: ~M[0]}

      # when
      changeset = Product.changeset(%Product{}, params)

      # then
      refute changeset.valid?
      assert changeset.errors[:price] == {"must be greater than zero", []}
    end

    test "reject a price lower than zero" do

      # given
      params = %{@valid_attrs | price: ~M[-1]}

      # when
      changeset = Product.changeset(%Product{}, params)

      # then
      refute changeset.valid?
      assert changeset.errors[:price] == {"must be greater than zero", []}
    end

  end
end