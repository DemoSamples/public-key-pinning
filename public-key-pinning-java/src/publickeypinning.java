import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.cert.Certificate;
import java.util.Base64;

import javax.net.ssl.HttpsURLConnection;

public class publickeypinning {


    public static void main(String[] args) {
      System.out.println("----------------- java ------------------");
      new publickeypinning().validatePublicKey(args[0]);
      System.out.println("\n-----------------------------------");
    }

    public void validatePublicKey(String urlString1) {
        System.out.println("[Native]: "  +
                "urlString: " + urlString1
        );
        String urlString = "https://api.github.com";
        try {


            URL url = new URL(urlString);
            HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
//            connection.connect();
//            connection.setDoOutput(true);
            connection.setRequestMethod("GET");
            //connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("Accept-Encoding", "Accept-Encoding");

            System.out.println("Response Code : " + connection.getResponseCode());
//            InputStream inputStream = connection.getInputStream();
//            int c;
//            while((c = inputStream.read()) != -1);

            print_content(connection);
            print_https_cert(connection);
          

        }catch (Exception e) {
            System.out.print(e);
        }
    }

    protected static String print16(PublicKey pub_key) {
        // use SHA256 to create a hash of secret_key and only then truncate it to secret_key_length
        MessageDigest digest=null;
        try {
            digest=MessageDigest.getInstance("SHA-256");
            digest.update(pub_key.getEncoded());
            return Base64.getEncoder().encodeToString(digest.digest());
            //return Util.byteArrayToHexString(digest.digest(), 0, 16);
        }
        catch(NoSuchAlgorithmException e) {
            return e.toString();
        }
    }

    private void print_https_cert(HttpsURLConnection con){

        //if(con!=null){

            try {
                con.connect();
                Certificate[] certs = con.getServerCertificates();
                for(Certificate cert1 : certs){

//                    System.out.println("Cert Type : " + cert1.getType());
//                    System.out.println("Cert Hash Code : " + cert1.hashCode());
//                    System.out.println("Cert Public Key Algorithm : "
//                            + cert1.getPublicKey().getAlgorithm());
//                    System.out.println("Cert Public Key Format : "
//                            + cert1.getPublicKey().getFormat());

                    System.out.print("Public Key: " + print16(cert1.getPublicKey()));


                }

            } catch (Exception e) {
                e.printStackTrace();

            }

        //}

    }

    private void print_content(HttpsURLConnection con){
        if(con!=null){

            try {

                System.out.println("****** Content of the URL ********");
                BufferedReader br =
                        new BufferedReader(
                                new InputStreamReader(con.getInputStream()));

                String input;

                while ((input = br.readLine()) != null){
                    System.out.println(input);
                }
                br.close();

            } catch (IOException e) {
                e.printStackTrace();
            }

        }

    }


}
