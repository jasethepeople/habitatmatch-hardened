defmodule HabitatMatch.Twilio do
  def start_verification(phone, locale \\ "en") do
    service = System.fetch_env!("TWILIO_VERIFY_SERVICE_SID")
    request("https://verify.twilio.com/v2/Services/#{service}/Verifications", %{"To" => phone, "Channel" => "sms", "Locale" => locale})
  end
  def check_verification(phone, code) do
    service = System.fetch_env!("TWILIO_VERIFY_SERVICE_SID")
    request("https://verify.twilio.com/v2/Services/#{service}/VerificationCheck", %{"To" => phone, "Code" => code})
  end
  def notify(phone, body) do
    sid = System.fetch_env!("TWILIO_MESSAGING_SERVICE_SID")
    request("https://api.twilio.com/2010-04-01/Accounts/#{System.fetch_env!("TWILIO_ACCOUNT_SID")}/Messages.json", %{"To" => phone, "MessagingServiceSid" => sid, "Body" => body}, :basic)
  end
  defp request(url, params, auth \\ :basic) do
    body = URI.encode_query(params)
    credentials = case auth do :basic -> Base.encode64(System.fetch_env!("TWILIO_API_KEY") <> ":" <> System.fetch_env!("TWILIO_API_SECRET")); end
    headers = [{"content-type", "application/x-www-form-urlencoded"}, {"authorization", "Basic " <> credentials}]
    req = Finch.build(:post, url, headers, body)
    case Finch.request(req, HabitatMatch.Finch) do
      {:ok, %Finch.Response{status: s, body: b}} when s in 200..299 -> Jason.decode(b)
      {:ok, %Finch.Response{status: s, body: b}} -> {:error, {:twilio_error, s, b}}
      {:error, e} -> {:error, {:twilio_network_error, e}}
    end
  end
end
