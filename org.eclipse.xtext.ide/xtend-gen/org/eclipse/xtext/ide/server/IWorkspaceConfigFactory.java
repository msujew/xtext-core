/**
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.eclipse.xtext.ide.server;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.workspace.IWorkspaceConfig;

/**
 * @author Jan Koehnlein - Initial contribution and API
 * @since 2.11
 */
@SuppressWarnings("all")
public interface IWorkspaceConfigFactory {
  public abstract IWorkspaceConfig getWorkspaceConfig(final URI workspaceBaseURI);
}
