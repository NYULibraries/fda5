package org.dspace.app.webui.components;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.dspace.authorize.AuthorizeException;
import org.dspace.content.Community;
import org.dspace.core.Context;
import org.dspace.plugin.CommunityHomeProcessor;
import org.dspace.plugin.PluginException;
/**
 * Created by katepechekhonova on 2/1/16.
 */
public class MostDownloadedCommunity implements CommunityHomeProcessor
{

    /**
     * blank constructor - does nothing
     *
     */
    public MostDownloadedCommunity()
    {

    }

    /* (non-Javadoc)
     * @see org.dspace.plugin.CommunityHomeProcessor#process(org.dspace.core.Context, javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse, org.dspace.content.Community)
     */
    public void process(Context context, HttpServletRequest request, HttpServletResponse response, Community community)
            throws PluginException, AuthorizeException
    {
        try
        {
            MostDownloadedManager md = new MostDownloadedManager(context);
            MostDownloaded recent = md.getMostDownloaded(community);
            request.setAttribute("most.downloadable", recent);
        }
        catch (MostDownloadedException e)
        {
            throw new PluginException(e);
        }
    }

}
