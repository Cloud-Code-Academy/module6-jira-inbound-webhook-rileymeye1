public interface IWebhookProcessor {

    Boolean validate(RestRequest request);

    void process(RestRequest request);
}