defmodule HabitatMatch.Documents.Document do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "documents" do
    belongs_to :user, HabitatMatch.Accounts.User, type: :binary_id
    field :filename, :string
    field :content_type, :string
    field :size_bytes, :integer
    field :sha256, :binary
    field :storage_key, :string
    field :expires_at, :date
    field :deleted_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end
end
