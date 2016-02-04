/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.kernel;

import org.dspace.services.ConfigurationService;

/**
 * This is the most core piece of the system:  instantiating one will
 * startup the dspace services framework.
 * 
 * @author Aaron Zeckoski (azeckoski @ gmail.com)
 */
public interface DSpaceKernel {

    String KERNEL_NAME = "Kernel";
    String MBEAN_PREFIX = "org.dspace:name=";
    String MBEAN_SUFFIX = ",type=DSpaceKernel";
    String MBEAN_NAME = MBEAN_PREFIX+KERNEL_NAME+MBEAN_SUFFIX;

    /**
     * @return the unique MBean name of this DSpace Kernel
     */
    String getMBeanName();

    /**
     * @return true if this Kernel is started and running
     */
    boolean isRunning();

    /**
     * @return the DSpace service manager instance for this Kernel
     */
    ServiceManager getServiceManager();

    /**
     * @return the DSpace configuration service for this Kernel
     */
    ConfigurationService getConfigurationService();

}
