defmodule Acme.Repo.Migrations.CreatePricingPoliciesHasProducts do
  use Ecto.Migration

  def change do
    create table(:promotions, primary_key: false) do
      add :product_id, references(:products, on_delete: :nothing, type: :binary_id), primary_key: true
      add :pricing_policy_id, references(:pricing_policies, on_delete: :nothing, type: :binary_id), primary_key: true

      timestamps()
    end

    create index(:promotions, [:product_id])
    create index(:promotions, [:pricing_policy_id])
  end
end
