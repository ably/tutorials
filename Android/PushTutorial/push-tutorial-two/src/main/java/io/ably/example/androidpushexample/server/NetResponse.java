package io.ably.example.androidpushexample.server;

import io.ably.lib.rest.DeviceDetails;

/**
 * Created by Amit S.
 * <p>
 * {"id":"123","platform":"android","formFactor":"phone","clientId":"123",
 * "metadata":"PST",
 * "deviceIdentityToken":{"token":"3VTWkw.DZ8Bwlh0DlOgSPrOHSQG7kTV4-_wY98KxwsBXSw2_aIl6J7WlHYit0DIZIPq-5H27ThmC1-Xv6BSPk_cd-1Lr7HMup_ndjkn62IiePZ3DkNgz5fvPgKMNB_iCZ47fbBbx","keyName":"3VTWkw.ZVWCgg","issued":1551196978541,"expires":1582732978541,"capability":"{}","clientId":"123","deviceId":"123"},"push":{"recipient":{"transportType":"fcm","registrationToken":"123"},"state":"ACTIVE"}}
 */
public class NetResponse {
    public String id;
    public String platform;
    public String formFactor;
    public String clientId;
    DeviceDetails.Push push;
}
