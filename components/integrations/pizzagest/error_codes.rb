module Integrations
  module Pizzagest
    module ErrorCodes
      TABLE = {
        "1000" =>	"Unknown client code",
        "1001" =>	"Bad request (token)",
        "1002" =>	"No results found",
        "1003" =>	"The user is already registered",
        "1004" =>	"Required parameter missing ( Param Name)",
        "1005" =>	"Required parameter empty (Param Name)",
        "1007" =>	"Required parameter type incorrect",
        "1008" =>	"Internal Web Server Error",
        "1009" =>	"User registered not validated",
        "1010" =>	"Wrong password",
        "1011" =>	"Wrong validate code",
        "1012" =>	"User validated",
        "1013" =>	"Order empty",
        "1014" =>	"User Not Registered",
        "1016" =>	"Email missing",
        "1017" =>	"Branch code missing",
        "1018" =>	"Order save fail",
        "3001" =>	"The order has no delivery fee",
        "3002" =>	"Branch has no service at the moment",
        "3003" =>	"Product has no stock",
        "3004" =>	"DeliveryDate incorrect",
      }
    end
  end
end
