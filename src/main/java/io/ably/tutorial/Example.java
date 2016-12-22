package io.ably.tutorial;

import com.google.gson.Gson;
import io.ably.lib.rest.AblyRest;
import io.ably.lib.rest.Auth;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.Capability;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

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
    public String auth(HttpServletRequest request, HttpServletResponse response) throws AblyException {
        String username = null;
        Cookie[] cookies = request.getCookies();
        for (Cookie cookie : cookies) {
            if (cookie.getName().equalsIgnoreCase("username")) {
                username = cookie.getValue();
                break;
            }
        }
        Auth.TokenParams tokenParams = new Auth.TokenParams();
        if (username == null) {
            tokenParams.capability = Capability.c14n("{ 'notifications': ['subscribe'] }");
        } else {
            tokenParams.capability = Capability.c14n("{ '*': ['publish', 'subscribe'] }");
            tokenParams.clientId = username;
        }
        Auth.TokenRequest tokenRequest = null;
        try {
            tokenRequest = ablyRest.auth.createTokenRequest(null, tokenParams);
            response.setHeader("Content-Type", "application/json");
            return new Gson().toJson(tokenRequest);
        } catch (AblyException e) {
            response.setStatus(500);
            return "Error requesting token: " + e.getMessage();
        }
    }

    /* Set a cookie when the user logs in */
    @RequestMapping(value = "/login", method = RequestMethod.GET)
    public String login(@RequestParam(name = "username", defaultValue = "anonymous") String username, HttpServletResponse response) throws IOException {
        /* Login the user without credentials. This is an over simplified authentication system to keep this tutorial simple */
        response.addCookie(new Cookie("username", username));
        response.sendRedirect("/");
        return "redirect:/";
    }

    /* Clear the cookie when the user logs outs */
    @RequestMapping(value = "/logout", method = RequestMethod.GET)
    public String logout(HttpServletRequest request, HttpServletResponse response) throws IOException {
        for (Cookie cookie : request.getCookies()) {
            if (cookie.getName().equalsIgnoreCase("username")) {
                cookie.setValue(null);
                cookie.setMaxAge(0);
                cookie.setPath(request.getContextPath());
                response.addCookie(cookie);
            }
        }
        response.sendRedirect("/");
        return "redirect:/";
    }
}
