defmodule HabitatMatchWeb.Router do
  use Phoenix.Router
  pipeline :api do
    plug :accepts, ["json"]
    plug HabitatMatchWeb.Plugs.SecurityHeaders
  end
  pipeline :public_auth do
    plug HabitatMatchWeb.Plugs.RateLimit, bucket: "auth", limit: 12, scale: 60_000
  end
  pipeline :auth do
    plug HabitatMatchWeb.Plugs.Auth
  end
  scope "/api", HabitatMatchWeb do
    pipe_through [:api, :public_auth]
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/phone/start", VerificationController, :start
    post "/auth/phone/check", VerificationController, :check
  end
  scope "/api", HabitatMatchWeb do
    pipe_through :api
    post "/webhooks/stripe", StripeController, :webhook
  end
  scope "/api", HabitatMatchWeb do
    pipe_through [:api, :auth]
    post "/auth/logout", AuthController, :logout
    get "/auth/me", AuthController, :me
    post "/auth/csrf", AuthController, :csrf
    post "/translate", TranslationController, :translate
    get "/buildings", BuildingController, :index
    post "/applications", ApplicationController, :create
    get "/applications", ApplicationController, :index
    get "/applications/:id", ApplicationController, :show
    post "/documents", DocumentController, :create
    get "/documents", DocumentController, :index
    get "/documents/:id/download", DocumentController, :download
    delete "/documents/:id", DocumentController, :delete
    post "/billing/checkout", BillingController, :checkout
    post "/billing/portal", BillingController, :portal
    get "/billing", BillingController, :show
  end
  match :*, "/*path", HabitatMatchWeb.FallbackController, :not_found
end
