package io.ably.tutorial;

import io.ably.lib.rest.AblyRest;
import io.ably.lib.types.AblyException;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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

    /* Add method index with RequestMapping annotation so the web app knows which method to use on our default URL */
    @RequestMapping(value = "/")
    public String index() {
        return "Hello, I am a very simple server";
    }
}
