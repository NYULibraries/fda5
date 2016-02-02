package org.dspace.app.webui.components;

import org.dspace.authorize.AuthorizeException;
import org.dspace.content.Collection;
import org.dspace.core.Context;
import org.dspace.plugin.CollectionHomeProcessor;
import org.dspace.plugin.PluginException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Created by katepechekhonova on 2/1/16.
 */
 public class MostDownloadedCollection implements CollectionHomeProcessor
    {
        /**
         * blank constructor - does nothing.
         *
         */
        public MostDownloadedCollection()
        {

        }

        /* (non-Javadoc)
         * @see org.dspace.plugin.CollectionHomeProcessor#process(org.dspace.core.Context, javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse, org.dspace.content.Community)
         */
        public void process(Context context, HttpServletRequest request, HttpServletResponse response, Collection collection)
                throws PluginException, AuthorizeException
        {
            try
            {
                MostDownloadedManager md = new MostDownloadedManager(context);
                MostDownloaded recent = md.getMostDownloaded(collection);
                request.setAttribute("most.downloadable", recent);
            }
            catch ( MostDownloadedException e)
            {
                throw new PluginException(e);
            }
        }
}
