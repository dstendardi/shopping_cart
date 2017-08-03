defmodule Acme.Repo.Migrations.CreateOrderItems do
  use Ecto.Migration

  def change do
    create table(:order_items, primary_key: false) do
      add :quantity, :integer
      add :product_id, references(:products, on_delete: :nothing, type: :binary_id), primary_key: true
      add :order_id, references(:orders, on_delete: :nothing, type: :binary_id), primary_key: true

      timestamps()
    end

    create index(:order_items, [:product_id])
    create index(:order_items, [:order_id])
  end
end
