/// Ekvivalent discoverCarsHTML() iz ResultView.swift — JS widget embed
/// (DiscoverCars), učitava se preko loadHtmlString jer je puna HTML
/// stranica sa <script> tag-om, ne obična URL. Affiliate ID (a_aid=stojanbn)
/// je poseban DiscoverCars nalog — NIJE isti kao Stay22-ov aid.
class DiscoverCarsService {
  DiscoverCarsService._();

  static String buildHtml() {
    return '''
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;">
  <div>
    <script id="dchwidget"
        src="https://www.discovercars.com/widget.js?v1"
        data-dev-env="com"
        data-location=""
        data-utm-source="https://www.discovercars.com/?a_aid=stojanbn"
        data-utm-medium="widget"
        data-aff-code="a_aid"
        data-autocomplete="on"
        data-style-submit-bg-color="#db7c26"
        data-style-submit-font-color="#ebf6ff"
        data-style-form-bg-color="#ebf6ff"
        data-style-form-font-color="#463730"
        data-style-submit-text="Search now"
        data-style-title-color="#0075a2"
        data-title-text="Search and compare car rentals and save up to 70%!"
        async="async"
        data-style_rounded_corners="on"
        data-localization_currency_box="on"
        data-layout_benefits="on"
        data-layout_description="on"
        data-layout_description_text="We've selected the best deals from our car rental partners."
        data-layout_logo_style="on dark"
        data-layout_style_form_bg_color="#007ac2"
        data-layout_title="on"
        data-layout_supplier_logos="on">
    </script>
  </div>
</body>
</html>
''';
  }
}
