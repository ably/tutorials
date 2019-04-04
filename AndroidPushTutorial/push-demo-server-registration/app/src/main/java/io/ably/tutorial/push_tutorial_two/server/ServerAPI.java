package io.ably.tutorial.push_tutorial_two.server;

import io.ably.tutorial.push_tutorial_two.BuildConfig;
import retrofit2.Call;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.http.GET;
import retrofit2.http.Query;

/**
 * Created by Amit S.
 */
public class ServerAPI {


    public interface API {
        @GET("/register")
        Call<NetResponse> register(@Query("deviceId") String deviceId, @Query("registrationToken") String registrationToken, @Query("clientId") String clientId);
    }


    private static ServerAPI instance;

    public static ServerAPI getInstance() {
        if (instance == null) {
            instance = new ServerAPI();
        }
        return instance;
    }

    private final API api;

    private ServerAPI() {
        Retrofit.Builder builder = new Retrofit.Builder();
        builder.baseUrl(BuildConfig.SERVER_BASE_URL);
        builder.addConverterFactory(GsonConverterFactory.create());

        Retrofit retrofit = builder.build();
        api = retrofit.create(API.class);
    }

    public API api() {
        return api;
    }
}
