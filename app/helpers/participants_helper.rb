module ParticipantsHelper
  def shipping_info_url(shipping_info)
    case TrackingNumber.new(shipping_info).carrier
    when :ups
      "https://wwwapps.ups.com/WebTracking/track?track=yes&trackNums=#{shipping_info}"
    when :fedex
      "https://www.fedex.com/apps/fedextrack/index.html?tracknumbers=#{shipping_info}&cntry_code=us"
    when :usps
      "https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=#{shipping_info}"
    when :dhl
      "http://www.dhl.com/content/g0/en/express/tracking.shtml?brand=DHL&AWB=#{shipping_info}"
    when :ontrac
      "https://www.ontrac.com/trackingres.asp?tracking_number=#{shipping_info}"
    else
      logger.error "Unknown carrier for tracking number: #{shipping_info}"
    end
  end
end
