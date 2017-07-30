defmodule Acme.Shopping.OrderTest do

  use Acme.DataCase

  alias Acme.Shopping.{Order, Product, Promotion}

  def default() do
     %Order{} |> Acme.Repo.insert!()
  end

  describe "add/1" do

    test "add single items to the shopping cart returns the item price" do

      # given
      tshirt = Acme.Repo.insert!(%Product{name: "tshirt", price: 20.0})

      # when
      price = Order.create()
        |> Order.add(tshirt.id)
        |> Order.price()

      # then
      assert tshirt.price == price
    end

    test "add several items of the same type returns the cumulated price" do

      # given
      tshirt = Acme.Repo.insert!(%Product{name: "tshirt", price: 20.0})

      # when
      price = Order.create()
        |> Order.add(tshirt.id)
        |> Order.add(tshirt.id)
        |> Order.price()

      # then
      assert tshirt.price * 2 == price
    end

    test "add one item per product returns the sum of each item price" do

      # given
      tshirt = Acme.Repo.insert!(%Product{name: "tshirt", price: 20.0})
      mug = Acme.Repo.insert!(%Product{name: "mug", price: 5.0})

      # when
      price = Order.create()
        |> Order.add(tshirt.id)
        |> Order.add(mug.id)
        |> Order.price()

      # then
      assert tshirt.price + mug.price == price
    end

    test "add non-existent product to the order throw Ecto.InvalidChangesetError" do

      # given
      unexistant_product_id = Ecto.UUID.generate()

      # when
      # then
      assert_raise Ecto.InvalidChangesetError, fn ->

        Order.create()
          |> Order.add(unexistant_product_id)
      end
    end

    test "reject exceeding max_item_per_order" do

      # given
      to_many_items_per_order = Application.get_env(:acme, :max_item_per_order) + 1

      products = Enum.map(1..to_many_items_per_order, fn(number) -> [
        name: "tshirt-#{number}",
        price: 20.0,
        inserted_at: Ecto.DateTime.utc,
        updated_at: Ecto.DateTime.utc
      ] end)

      {_, created_products} = Acme.Repo.insert_all(Product, products, returning: [:id])

      # when
      # then
      assert_raise Ecto.InvalidChangesetError, fn ->

        Enum.reduce(created_products, Order.create(), fn(%Product{id: product_id}, order) ->
           order|> Order.add(product_id)
        end)
      end

    end

    test "reject exceeding max_quantity_per_item" do

      # given
      max_quantity_per_item = Application.get_env(:acme, :max_quantity_per_item) + 1

      tshirt = Acme.Repo.insert!(%Product{name: "tshirt", price: 20.0})

      # when
      # then
      assert_raise Ecto.InvalidChangesetError, fn ->

        Enum.reduce(1..max_quantity_per_item, Order.create(), fn(_, order) ->
           order|> Order.add(tshirt.id)
        end)
      end

    end
  end

  describe("price") do

    def create_product_with_policy(name, price, policy) do
        product = Acme.Repo.insert!(%Product{name: name, price: price})
        policy = Acme.Repo.insert!(%Acme.Shopping.PricingPolicy{name: policy, rule: policy})
        Acme.Repo.insert!(%Promotion{product_id: product.id, pricing_policy_id: policy.id})
        product
    end

    test "with no item returns zero" do

      # when
      price = Order.create()
      |> Order.price()

      # then
      assert 0 == price
    end

    test "with no product elligible to promotion" do

      # given
      tshirt = create_product_with_policy("tshirt", 20.0, "DegressivePolicy")
      voucher = create_product_with_policy("voucher", 5.0, "BundlePolicy")
      mug =  Acme.Repo.insert!(%Product{name: "mug", price: 7.50})

      # when
      price = Order.create()
      |> Order.add(voucher.id)
      |> Order.add(tshirt.id)
      |> Order.add(mug.id)
      |> Order.price()

      # then
      assert 32.50 == price
    end

    test "with bundle policy applied to voucher" do

      # given
      tshirt = create_product_with_policy("tshirt", 20.0, "DegressivePolicy")
      voucher = create_product_with_policy("voucher", 5.0, "BundlePolicy")

      # when
      price = Order.create()
      |> Order.add(voucher.id)
      |> Order.add(tshirt.id)
      |> Order.add(voucher.id)
      |> Order.price()

      # then
      assert 25.0 == price
    end

    test "with degressive policy applied to tshirt" do

      # given
      tshirt = create_product_with_policy("tshirt", 20.0, "DegressivePolicy")
      voucher = create_product_with_policy("voucher", 5.0, "BundlePolicy")

      # when
      price = Order.create()
      |> Order.add(tshirt.id)
      |> Order.add(tshirt.id)
      |> Order.add(tshirt.id)
      |> Order.add(voucher.id)
      |> Order.add(tshirt.id)
      |> Order.price()

      # then
      assert 81.00 == price
    end


    test "with degressive and bundle policy applied distincly to tshirt and voucher" do

      # given
      tshirt = create_product_with_policy("tshirt", 20.0, "DegressivePolicy")
      voucher = create_product_with_policy("voucher", 5.0, "BundlePolicy")
      mug = Acme.Repo.insert!(%Product{name: "mug", price: 7.50})

      # when
      price = Order.create()
      |> Order.add(voucher.id)
      |> Order.add(tshirt.id)
      |> Order.add(voucher.id)
      |> Order.add(voucher.id)
      |> Order.add(mug.id)
      |> Order.add(tshirt.id)
      |> Order.add(tshirt.id)
      |> Order.price()

      # then
      assert 74.50 == price
    end
  end

end