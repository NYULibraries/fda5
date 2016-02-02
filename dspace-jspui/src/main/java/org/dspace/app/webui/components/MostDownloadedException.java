package org.dspace.app.webui.components;

import org.dspace.sort.SortException;

/**
 * Created by katepechekhonova on 2/1/16.
 */
public class MostDownloadedException extends Exception {

    public MostDownloadedException() {
        super();
    }

    public MostDownloadedException(String message) {
        super(message);
    }

    public MostDownloadedException(String message, Throwable cause) {
        super(message, cause);

    }

    public MostDownloadedException(Throwable cause) {
        super(cause);

    }


}