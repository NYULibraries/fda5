package org.dspace.app.webui.components;

import org.dspace.authorize.AuthorizeException;
import org.dspace.core.Context;
import org.dspace.plugin.PluginException;
import org.dspace.plugin.SiteHomeProcessor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Created by katepechekhonova on 2/1/16.
 */
public class MostDownloadedSite implements SiteHomeProcessor
{

    /**
     * blank constructor - does nothing.
     *
     */
    public MostDownloadedSite()
    {

    }

    /* (non-Javadoc)
     * @see org.dspace.plugin.CommunityHomeProcessor#process(org.dspace.core.Context, javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse, org.dspace.content.Community)
     */
    @Override
    public void process(Context context, HttpServletRequest request, HttpServletResponse response)
            throws PluginException, AuthorizeException
    {
        try
        {
            MostDownloadedManager md = new  MostDownloadedManager(context);
            MostDownloaded recent = md.getMostDownloaded(null);
            request.setAttribute("most.downloaded", recent);

        }
        catch (MostDownloadedException e)
        {
            throw new PluginException(e);
        }
    }
}
