defmodule Acme.Shopping.PricingPolicy do

  @moduledoc """
  Pricing policy computes the pricing rules for a given order.
  The `code` attributes refers to the function responsible for computation.

  We plan in next story to implement the rule by calling dynamically the module like this

  ```
  module = String.to_existing_atom("Acme.Shopping.PricingPolicy.{policy.rule}
  apply(nodule, :apply_policy, [])
  ```

  For now the functions does not receive parameters, but it could be done pretty easily
  by adding an embed structure representing the parameters.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Acme.Shopping.PricingPolicy

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pricing_policies" do
    field :rule, :string
    field :name, :string
    many_to_many :products, Acme.Shopping.Product, join_through: "promotions"

    timestamps()
  end

  @doc false
  def changeset(%PricingPolicy{} = pricing_policy, attrs) do
    pricing_policy
    |> cast(attrs, [:name, :rule])
    |> validate_required([:name, :rule])
    |> validate_change(:rule, &validate_rule_change/2)
  end

  @doc """
    Checks for existence of the rule declared inside the code base

    Important : since the code can change without validation
    on database (opposite worklow) developper editing rules should
    be aware of what is referenced in the database
  """
  def validate_rule_change(:rule, rule) do

    exported = try do
      rule
      |> atom_from_rule()
      |> function_exported?(:apply_policy, 1)
    rescue
        ArgumentError -> false
    end

    if exported do [] else [rule: "Not defined in codebase"] end
  end

  def apply_rule(rule, params) do

   module = try do
      atom_from_rule(rule)
    rescue
      ArgumentError -> Acme.Shopping.PricingPolicy.DefaultPolicy
    end

    apply(module, :apply_policy, [params])
  end

  defp atom_from_rule(rule) do
     "Elixir.Acme.Shopping.PricingPolicy.#{rule}" |> String.to_existing_atom()
  end

  defmodule DefaultPolicy do

    @moduledoc """
    A simple policy that compute the regular price
    for the shopping cart.
    """

    def apply_policy({price, quantity}) do
      Money.multiply(price, quantity)
    end
  end

  defmodule BundlePolicy do

    @moduledoc """
    Bundle policy works gives one item free for one item bought.

    ## Examples

    iex> apply_policy({Money.new(20_00), 2})
    Money.new(20_00)

    iex> apply_policy({Money.new(20_00), 3})
    Money.new(40_00)

    iex> apply_policy({Money.new(20_00), 1})
    Money.new(20_00)

    iex> apply_policy({Money.new(20_00), 0})
    Money.new(0)
    """

    def apply_policy({price, quantity}) do

      bundles = Float.floor(quantity / 2)

      remainder = rem(quantity, 2)

      price
      |> Money.multiply(bundles)
      |> Money.add(Money.multiply(price, remainder))

    end
  end

  defmodule DegressivePolicy do

    @moduledoc """
    Degressive policy lower the price when the quantity reach a threshold
    The threshold is currently hadcorded to three items

    ## Examples

    iex> apply_policy({Money.new(20_00), 2})
    Money.new(40_00)

    iex> apply_policy({Money.new(20_00), 3})
    Money.new(57_00)

    iex> apply_policy({Money.new(20_00), 0})
    Money.new(0)
    """

    def apply_policy({price, quantity}) do

      # to be replaced
      threshold = 3
      percentage = 5

      price_after_reduction = if quantity >= threshold do

        %{amount: amount} = Money.multiply(price, percentage)
        reduction = Money.new(round(amount / 100))

        Money.subtract(price, reduction)
      else
        price
      end

      Money.multiply(price_after_reduction, quantity)
    end
  end
end
