package io.ably.tutorial.push_tutorial_two.server;

import io.ably.lib.rest.DeviceDetails;

/**
 * Created by Amit S.
 * <p>
 * {"id":"123","platform":"android","formFactor":"phone","clientId":"123",
 * "metadata":"PST",
 * "deviceIdentityToken":{"token":"TOKEN","keyName":"KEY_NAME","issued":1551196978541,"expires":1582732978541,"capability":"{}","clientId":"123","deviceId":"123"},"push":{"recipient":{"transportType":"fcm","registrationToken":"123"},"state":"ACTIVE"}}
 */
public class NetResponse {
    public String id;
    public String platform;
    public String formFactor;
    public String clientId;
    DeviceDetails.Push push;
}
