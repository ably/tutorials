package io.ably.tutorial;

import com.google.gson.Gson;
import io.ably.lib.rest.AblyRest;
import io.ably.lib.rest.Auth;
import io.ably.lib.types.AblyException;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@RestController
public class Example {

    private final static String API_KEY = "INSERT-YOUR-API-KEY-HERE"; /* Sign up at ably.io to get your API key */

    /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
    static {
        if (API_KEY.contains("INSERT")) {
            throw new RuntimeException("API key is not set, sign up at ably.io to get yours");
        }
    }

    private AblyRest ablyRest;

    public Example() {
        try {
            initAbly();
        } catch (AblyException e) {
            e.printStackTrace();
        }
    }

    /* Add AblyException to method signature as AblyRest constructor can throw one */
    private void initAbly() throws AblyException {
        ablyRest = new AblyRest(API_KEY);
    }

    /* Issue token requests to clients sending a request to the /auth endpoint */
    @RequestMapping("/auth")
    public String auth(HttpServletRequest request, HttpServletResponse response) {
        Auth.TokenParams tokenParams = new Auth.TokenParams(); /* Use token defaults for now */
        try {
            Auth.TokenRequest tokenRequest = ablyRest.auth.createTokenRequest(null, tokenParams);
            response.setHeader("Content-Type", "application/json");
            return new Gson().toJson(tokenRequest);
        } catch (AblyException e) {
            response.setStatus(500);
            return "Error requesting token: " + e.getMessage();
        }
    }
}
