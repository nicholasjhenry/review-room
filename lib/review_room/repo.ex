defmodule ReviewRoom.Repo do
  use Ecto.Repo,
    otp_app: :review_room,
    adapter: Ecto.Adapters.Postgres
end
