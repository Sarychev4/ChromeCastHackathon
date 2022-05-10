//
//  DefaultAppConfiguration.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import Foundation
let DefaultAppConfiguration = """
{
  "ratings": {
    "spots": {
      "on_after_tutorial": {
        "type": "ronating",
        "is_enabled": false,
        "max_impressions_count": 1,
        "actions_count_befor_start": 0,
        "actions_skip_count_after_start": 0
      }
    },
    "review_url": "https://apps.apple.com/app/id1586624313?action=write-review",
    "impressions_count_per_session": 1000
  },
  "subscriptions": {
    "spots": {
      "iptv": {
        "is_enabled": true,
        "configuration": "2products",
        "is_special_offer_enabled": true,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "intro": {
        "is_enabled": true,
        "configuration": "2products",
        "presentation_style": "fade",
        "is_special_offer_enabled": false,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "introSpecialOffer": {
        "is_enabled": false,
        "configuration": "2products",
        "presentation_style": "fade",
        "is_special_offer_enabled": true,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "banner": {
        "is_enabled": true,
        "configuration": "2products",
        "is_special_offer_enabled": true,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "you_tube": {
        "is_enabled": true,
        "configuration": "2products",
        "is_special_offer_enabled": true,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "browser": {
        "is_enabled": true,
        "configuration": "2products",
        "is_special_offer_enabled": true,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "settings": {
        "is_enabled": true,
        "configuration": "2products",
        "is_special_offer_enabled": true,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "resolution": {
        "is_enabled": true,
        "configuration": "2products",
        "is_special_offer_enabled": true,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      },
      "session_start": {
        "is_enabled": true,
        "configuration": "2products",
        "is_special_offer_enabled": false,
        "actions_count_befor_start": 0,
        "special_offer_configuration": "special_offer",
        "actions_skip_count_after_start": 0
      }
    },
    "products": {
      "Yearly": {
        "id": "com.appflair.yearly",
        "type": 1
      },
      "Lifetime": {
        "id": "com.appflair.onetime",
        "type": 0
      },
      "Yearly Special": {
        "id": "com.appflair.yearlyoffer",
        "type": 1
      },
      "Yearly Higher": {
        "id": "com.appflair.yearlyhigher",
        "type": 1
      },
      "Weekly Trial": {
        "id": "com.appflair.weeklytrial",
        "type": 1
      }
    },
    "special_offer": {
      "price_text": {
        "en": "Unlock everything for [price]/year\\nor just [divided_price]/month. Cancel anytime.",
        "de": "Alles freischalten für nur [divided_price]/Monat. [price]/Jahr. Beliebig kündbar.",
        "pt": "Libere tudo por apenas US [divided_price]/mês. US [price] anuais. Cancele quando quiser."
      },
      "product_id": "Yearly Special",
      "price_divider": 12,
      "discount_value": 0.5,
      "is_bouncing_enabled": true,
      "is_special_offer_enabled": true,
      "special_offer_time_value": 43200
    },
    "configurations": {
      "common": {
        "caption": {
          "en": "READY TO USE",
          "de": "SIE SIND BEREIT!",
          "pt": "TUDO PRONTO"
        },
        "subcaption": {
          "en": "Unlock everything for [price]/year\\nor just [divided_price]/month. Cancel anytime.",
          "de": "Alles freischalten für nur  [divided_price]/Monat; [price]/Jahr. Beliebig kündbar.",
          "pt": "Libere tudo por apenas US [divided_price]/mês. US [price] anuais. Cancele quando quiser."
        },
        "first_button": {
          "product_id": "Yearly",
          "price_divider": 12
        },
        "is_bouncing_enabled": true,
        "is_bold": true,
        "font_size": 18
      },
      "2products": {
        "caption": {
           "en": "READY TO USE",
           "de": "SIE SIND BEREIT!",
           "pt": "TUDO PRONTO"
         },
        "first_button": {
            "color": "#FFFFFF",
            "title": {
                "en": "Yearly access. Only [divided_price]/month",
                "de": "Jahresabo. Nur [divided_price]/Monat",
                "pt": "Acesso anual. Só US [divided_price]/mês"
            },
            "subtitle": {
                "en": "Save up to 50%, billed yearly [price]",
                "de": "Pare bis zu 50 %, [price]/Jahr",
                "pt": "Economize até 50%: US [price] anuais."
            },
            "product_id": "Yearly",
            "price_divider": 12
        },
        "second_button": {
            "color": "#FFFFFF",
            "title": {
                "en": "Lifetime access to everything",
                "de": "Lebenslanger Zugriff auf alles",
                "pt": "Acesso vitalício a tudo"
            },
            "subtitle": {
                "en": "Only pay once and enjoy, just [price]",
                "de": "Nur einmal zahlen, nur [price]",
                "pt": "Pague uma vez e aproveite: só US [price]"
            },
            "product_id": "Lifetime"
        },
        "is_bouncing_enabled": true
      }
    }
  },
  "tutorial_skip_button_enabled": false,
  "tutorial_questions_enabled": false,
  "tutorial_rating_enabled": false,
  "tutorial_rating_type": "stars",
  "support_email": "supportsm@appflair.io",
  "hide_close_button_for_attributedUser": false,
  "web_apps": {
    "chromecast": {
      "prod": {
        "id": "2C5BA44D",
        "channel": "urn:x-cast:com.mirroring.screen.sharing"
      },
      "dev": {
        "id": "785537D5",
        "channel": "urn:x-cast:com.mirroring.screen.sharing"
      }
    },
    "roku": {
      "prod": {
        "id": "658625"
      }
    }
  }
}
"""
