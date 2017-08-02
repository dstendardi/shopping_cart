defmodule Acme.Shopping.OrderItemTest do

  use Acme.DataCase
  import Money.Sigils
  alias Acme.Shopping.{Order, Product, OrderItem, ProductTest, OrderTest}

  describe "changeset" do

    @max_quantity_per_item Application.get_env(:acme, :max_quantity_per_item)

    test "reject quantity exceeding <max_quantity_per_item>" do

      # given
      params = %{
        product_id: ProductTest.default().id,
        order_id: OrderTest.default().id,
        quantity: @max_quantity_per_item + 1
      }

      # when
      changeset = %OrderItem{} |> OrderItem.changeset(params)

      # then
      refute changeset.valid?
      assert changeset.errors[:quantity] == {"Too many items for product", []}
    end

    test "reject quantity exceeding <max_quantity_per_item> considering existing quantity" do

      # given
      %OrderItem{
        product_id: ProductTest.default().id,
        order_id: OrderTest.default().id,
        quantity: 1
      } |> Acme.Repo.insert!

      params = %{
        product_id: ProductTest.default().id,
        order_id: OrderTest.default().id,
        quantity: @max_quantity_per_item
      }

      # when
      changeset = %OrderItem{} |> OrderItem.changeset(params)

      # then
      refute changeset.valid?
      assert changeset.errors[:quantity] == {"Too many items for product", []}
    end

    @max_item_per_order Application.get_env(:acme, :max_item_per_order)

    test "reject more than <max_item_per_order>" do

      # given
      order = %Order{} |> Acme.Repo.insert!()

      order = Enum.reduce(1..@max_item_per_order, order, fn(num, order) ->
          product = %Product{name: "tshift #{num}", price: ~M[20_00] } |> Acme.Repo.insert!
          order |> Order.add(product.id)
      end)

      after_eight = %Product{name: "after eight", price: ~M[20_00] } |> Acme.Repo.insert!

      # when
      changeset = %OrderItem{} |> OrderItem.changeset(%{product_id: after_eight.id, order_id: order.id, quantity: 1})

      # then
      refute changeset.valid?
      assert changeset.errors[:order_id] == {"Too many products", []}
    end

    test "reject empty params" do

      # given
      params = %{}

      # when
      changeset = %OrderItem{} |> OrderItem.changeset(params)

      # then
      refute changeset.valid?
      assert changeset.errors[:product_id] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:order_id] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:quantity] == {"can't be blank", [validation: :required]}
    end

    test "reject non-existent product" do

      # given
      order = %Order{} |> Acme.Repo.insert!()

      # when
      {:error, changeset} = %OrderItem{}
        |> OrderItem.changeset(%{product_id: Ecto.UUID.generate(), order_id: order.id, quantity: 1})
        |> Acme.Repo.insert

      # then
      refute changeset.valid?
      assert changeset.errors[:product_id] == {"does not exist", []}
    end

    test "reject non-existent order" do

      # given
      tshirt = %Product{name: "tshirt", price: ~M[20_00] } |> Acme.Repo.insert!

      # when
      {:error, changeset} = %OrderItem{}
        |> OrderItem.changeset(%{product_id: tshirt.id, order_id: Ecto.UUID.generate(), quantity: 1})
        |> Acme.Repo.insert

      # then
      refute changeset.valid?
      assert changeset.errors[:order_id] == {"does not exist", []}
    end
  end
end