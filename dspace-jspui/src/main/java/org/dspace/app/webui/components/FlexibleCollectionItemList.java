/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.webui.components;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.apache.tools.ant.filters.TokenFilter;
import org.dspace.authorize.AuthorizeException;
import org.dspace.app.webui.util.UIUtil;
import org.dspace.content.Collection;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Context;
import org.dspace.plugin.CollectionHomeProcessor;
import org.dspace.plugin.PluginException;
import org.dspace.browse.BrowseEngine;
import org.dspace.browse.BrowseIndex;
import org.dspace.browse.BrowseInfo;
import org.dspace.browse.BrowserScope;
import org.dspace.browse.BrowseException;
import org.dspace.sort.SortException;
import org.dspace.sort.SortOption;


/**
 * This class obtains item list of the given collection by
 * implementing the CollectionHomeProcessor.
 * It reads the name of the index from dspace.cfg
 * For most collections we will use standard indexes- title and dateissued
 * the class creates BrowseInfo object which will be used by BrowseItemList tag
 *
 * @author Kate Pechekhonova
 *
 */
public class FlexibleCollectionItemList implements CollectionHomeProcessor
{

    /** log4j category */
    private static Logger log = Logger.getLogger(FlexibleCollectionItemList.class);

    //default indexes used by collection if collection specific indexed are not specified. All available indexes are defined in dspace.cfg
    private static String names_str=UIUtil.getProperty("webui.collectionhome.browse","title,dateissued");

    //default number of authors which should be displayed, if not defined all authors will be displayed
    private static int etal    = ConfigurationManager.getIntProperty("webui.browse.author-limit", -1);

    //default sorting order of items, could be "desc" or "asc". If not defined "asc" will be used
    private static int sort_option_default=ConfigurationManager.getIntProperty("webui.collectionhome.sort",1);

    //default sorting order of items, could be "desc" or "asc". If not defined "asc" will be used
    private static String data_order_default=UIUtil.getProperty("webui.collectionhome.order_default","desc");


    /**
     * blank constructor - does nothing.
     *
     */
    public FlexibleCollectionItemList()
    {

    }

    /* returns the index of items
     */
    public void process(Context context, HttpServletRequest request, HttpServletResponse response, Collection collection)
            throws PluginException, AuthorizeException
    {
        //defines array of indexes available for those collection in case nothing is defined in config
        String[] names=null;

        String names_str_col=ConfigurationManager.getProperty("webui.collectionhome.browse."+collection.getHandle());

        if(names_str_col!=null)
        {
            names= names_str_col.split(",");
        }
        else
        {
            if(names_str!=null) {
                names = names_str.split(",");
            }
        }


        int offset = UIUtil.getIntParameter(request, "offset");
        //defines the number of index from the array of indexes which will be used. It is choosen by the user on the collection home page
        //If null the defult sort option will be used
        int number= UIUtil.getIntParameter(request, "index");
        //defines the number of sort option which will be used. It is choosen by the user on the collection home page
        //If null the defult sort option will be used
        int sort_option_number= UIUtil.getIntParameter(request, "value");
        //defines sorting options "desc" or "asc"
        String data_order=request.getParameter("data-order");
        //defines the number of results per page
        int perpage=UIUtil.getIntParameter(request, "rpp");

        if (offset < 0)
        {
            offset = 0;
        }

        try
        {
            BrowseIndex bi =null;
            if(number>0&&(number-1)<names.length)
                bi = BrowseIndex.getBrowseIndex(names[number-1]);
            else

                bi = BrowseIndex.getBrowseIndex(names[0]);

            if(bi==null)
            {
                if(number>0&&(number-1)<names.length)
                    bi = BrowseIndex.getCollectionBrowseIndex(names[number-1]);
                else
                    bi = BrowseIndex.getCollectionBrowseIndex(names[0]);
            }

            if (bi == null || !"item".equals(bi.getDisplayType()))
            {
                request.setAttribute("show.items", Boolean.FALSE);
                return;
            }

            BrowserScope scope = new BrowserScope(context);
            scope.setBrowseContainer(collection);
            scope.setBrowseIndex(bi);
            scope.setEtAl(etal);
            scope.setOffset(offset);
            scope.setResultsPerPage(perpage);

            //defines what sort option from the sort options array will be used for sorting
            if(sort_option_number==0)
            {
                if (bi.getSortOption() != null)
                    sort_option_number = bi.getSortOption().getNumber();
                else
                    sort_option_number = sort_option_default;
            }
            scope.setSortBy(sort_option_number);

            //defines if order will be "desc" or "asc"
            if(data_order==null)
                data_order=bi.getDefaultOrder();
            if(data_order==null)
                data_order=data_order_default;

            if (data_order.equalsIgnoreCase("desc"))
                scope.setOrder(SortOption.DESCENDING);
            else
                scope.setOrder(SortOption.ASCENDING);

            BrowseEngine be = new BrowseEngine(context);
            BrowseInfo binfo = be.browse(scope);
            request.setAttribute("browse.info", binfo);


            if (binfo.hasResults())
            {
                request.setAttribute("show.items", Boolean.TRUE);
            }
            else
            {
                request.setAttribute("show.items", Boolean.FALSE);
            }
        }
        catch (BrowseException e)
        {
            log.error(e.getMessage());
            request.setAttribute("show.items", Boolean.FALSE);
        }
    }
}

