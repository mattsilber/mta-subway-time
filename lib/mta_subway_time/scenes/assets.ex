defmodule MtaSubwayTime.Assets do
  use Scenic.Assets.Static,
      otp_app: :mta_subway_time,
      sources: [
        "assets",
        {:scenic, "#{System.get_env("MIX_DEPS_PATH") || "deps"}/scenic/assets"}
      ],
      alias: [
        roboto: "fonts/Roboto-Regular.ttf",
        roboto_black: "fonts/Roboto-Black.ttf"
      ]
end