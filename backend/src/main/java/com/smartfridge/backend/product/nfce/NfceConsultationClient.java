package com.smartfridge.backend.product.nfce;

import java.net.URI;

public interface NfceConsultationClient {

    String fetch(URI consultationUri);
}
