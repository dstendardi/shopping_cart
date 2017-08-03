defmodule Acme.Repo.Migrations.CreatePricingPolicies do
  use Ecto.Migration

  def change do
    create table(:pricing_policies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :rule, :string

      timestamps()
    end

  end
end
