package org.eclipse.xtext.xtext.wizard
import static org.eclipse.xtext.xtext.wizard.ExternalDependency.*
import org.eclipse.xtext.xtext.wizard.ecore2xtext.Ecore2XtextGrammarCreator

class RuntimeProjectDescriptor extends TestedProjectDescriptor {
	val grammarCreator = new Ecore2XtextGrammarCreator
	val RuntimeTestProjectDescriptor testProject
	
	new(WizardConfiguration config) {
		super(config)
		testProject = new RuntimeTestProjectDescriptor(this)
	}
	
	override isEnabled() {
		true
	}
	
	override setEnabled(boolean enabled) {
		throw new UnsupportedOperationException("The runtime project is always enabled")
	}
	
	override getNameQualifier() {
		""
	}
	
	override isEclipsePluginProject() {
		config.preferredBuildSystem == BuildSystem.ECLIPSE || config.uiProject.enabled
	}
	
	override isPartOfGradleBuild() {
		true
	}
	
	override isPartOfMavenBuild() {
		true
	}
	
	override getTestProject() {
		testProject
	}
	
	override getExternalDependencies() {
		val deps = newHashSet
		deps += super.externalDependencies
		deps += createXtextDependency("org.eclipse.xtext")
		deps += createXtextDependency("org.eclipse.xtext.xbase")
		deps += new ExternalDependency => [
			p2 [
				bundleId = "org.eclipse.equinox.common"
				version = "3.5.0"
			]
		]
		for (ePackage: config.ecore2Xtext.EPackageInfos) {
			deps += createBundleDependency(ePackage.bundleID)
			if (ePackage.genmodelURI.fileExtension == "xcore") {
				deps += createBundleDependency("org.eclipse.emf.ecore.xcore")
			}
		}
		deps
	}
	
	override getDevelopmentBundles() {
		#{
			"org.eclipse.xtext.xbase", 
			"org.eclipse.xtext.generator",
			"org.eclipse.xtext.xtext.generator",
			"org.apache.commons.logging", 
			"org.eclipse.emf.codegen.ecore", 
			"org.eclipse.emf.mwe.utils",
			"org.eclipse.emf.mwe2.launch",
			"org.eclipse.xtext.common.types", 
			"org.objectweb.asm",
			"org.apache.log4j"
		}
	}
	
	override getBinIncludes() {
		val includes = newHashSet
		includes += super.binIncludes
		includes += "plugin.xml"
		includes
	}

	override getFiles() {
		val files = newArrayList
		files += super.files
		files += file(Outlet.MAIN_RESOURCES, grammarFilePath, grammar)
		files += file(Outlet.MAIN_RESOURCES, workflowFilePath, workflow)
		return files
	}
	
	def String getGrammarFilePath() {
		return '''�config.language.basePackagePath�/�config.language.simpleName�.xtext'''
	}
	

	def grammar() {
		if (fromExistingEcoreModels)
			grammarCreator.grammar(config)
		else
			defaultGrammar
	}
	
	private def defaultGrammar() '''
		grammar �config.language.name� with org.eclipse.xtext.common.Terminals
		
		generate �config.language.simpleName.toFirstLower� "�config.language.nsURI�"
		
		Model:
			greetings+=Greeting*;
			
		Greeting:
			'Hello' name=ID '!';
	'''
	
	def String getWorkflowFilePath() {
		'''�config.language.basePackagePath�/Generate�config.language.simpleName�.mwe2'''
	}
	
	def workflow() {
		''' 
			module �(config.language.basePackagePath+"/Generate"+config.language.simpleName).replaceAll("/", ".")�
			
			import org.eclipse.emf.mwe.utils.*
			import org.eclipse.xtext.xtext.generator.*
			import org.eclipse.xtext.generator.*
			import org.eclipse.xtext.ui.generator.*
			
			var projectName = "�name�"
			var projectPath = "../${projectName}"
			
			var fileExtensions = "�config.language.fileExtensions�"
			var grammarURI = "platform:/resource/${projectName}/�Outlet.MAIN_RESOURCES.sourceFolder�/�grammarFilePath�"
			
			var encoding = "�config.encoding�"
			var lineDelimiter = "\n"
			var fileHeader = "/*\n * generated by Xtext \${version}\n */"

			Workflow {
			    bean = StandaloneSetup {
					scanClassPath = true
					�FOR p : config.enabledProjects.filter[it != config.parentProject]�
						projectMapping = { projectName = '�p.name�' path = '${projectPath}/../�p.name�' }
					�ENDFOR�
					�IF fromExistingEcoreModels�
						�FOR ePackageInfo : config.ecore2Xtext.EPackageInfos.filter[genmodelURI.fileExtension != "xcore"].map[EPackageJavaFQN].filterNull�
							registerGeneratedEPackage = "�ePackageInfo�"
						�ENDFOR�
						�FOR genmodelURI : config.ecore2Xtext.EPackageInfos.filter[genmodelURI.fileExtension != "xcore"].map[genmodelURI.toString].toSet�
							registerGenModelFile = "�genmodelURI�"
						�ENDFOR�
					�ELSE�
						// The following two lines can be removed, if Xbase is not used.
						registerGeneratedEPackage = "org.eclipse.xtext.xbase.XbasePackage"
						registerGenModelFile = "platform:/resource/org.eclipse.xtext.xbase/model/Xbase.genmodel"
					�ENDIF�
				}
				
				�FOR p : config.enabledProjects�
					component = DirectoryCleaner {
						directory = "${projectPath}�p.nameQualifier�/�Outlet.MAIN_SRC_GEN.sourceFolder�"
					}
				�ENDFOR�
				
				component = DirectoryCleaner {
					directory = "${projectPath}/model/generated"
				}
				
				component = XtextGenerator auto-inject {
					configuration = {
						project = WizardConfig {
							runtimeRoot = projectPath
							�IF config.uiProject.enabled�
								eclipseEditor = true
							�ENDIF�
							�IF config.intellijProject.enabled�
								ideaEditor = true
							�ENDIF�
							�IF config.webProject.enabled�
								webSupport = true
							�ENDIF�
							�IF config.ideProject.enabled�
								genericIdeSupport = true
							�ENDIF�
							�IF testProject.enabled�
								testingSupport = true
							�ENDIF�
							�IF config.sourceLayout == SourceLayout.MAVEN�
								mavenLayout = true
							�ENDIF�
						}
						code = auto-inject {
							preferXtendStubs = true
						}
					}
					language = auto-inject {
						uri = grammarURI
						�FOR genmodelURI : config.ecore2Xtext.EPackageInfos.filter[genmodelURI.fileExtension == "xcore"].map[genmodelURI.toString].toSet�
							loadedResource = "�genmodelURI�"
						�ENDFOR�
			
						// Java API to access grammar elements (required by several other fragments)
						fragment = grammarAccess.GrammarAccessFragment2 auto-inject {}
						
						�IF fromExistingEcoreModels�
							fragment = adapter.FragmentAdapter { 
								fragment = ecore2xtext.Ecore2XtextValueConverterServiceFragment auto-inject {}
							}
						�ENDIF�
				
						// generates Java API for the generated EPackages
						fragment = adapter.FragmentAdapter { 
							fragment = ecore.EMFGeneratorFragment auto-inject {
								javaModelDirectory = "/${projectName}/�Outlet.MAIN_SRC_GEN.sourceFolder�"
								updateBuildProperties = �isEclipsePluginProject�
							}
						}
			
						fragment = adapter.FragmentAdapter {
							fragment = serializer.SerializerFragment auto-inject {
								generateStub = false
							}
						}
			
						// a custom ResourceFactory for use with EMF
						fragment = adapter.FragmentAdapter {
							fragment = resourceFactory.ResourceFactoryFragment auto-inject {}
						}
			
						// The antlr parser generator fragment.
						fragment = adapter.FragmentAdapter {
							fragment = parser.antlr.XtextAntlrGeneratorFragment auto-inject {}
						}
			
						// Xtend-based API for validation
						fragment = adapter.FragmentAdapter {
							fragment = validation.ValidatorFragment auto-inject {
							//    composedCheck = "org.eclipse.xtext.validation.NamesAreUniqueValidator"
							}
						}
			
						// scoping and exporting API
						fragment = adapter.FragmentAdapter {
							fragment = scoping.ImportNamespacesScopingFragment auto-inject {}
						}
						fragment = adapter.FragmentAdapter {
							fragment = exporting.QualifiedNamesFragment auto-inject {}
						}
			
						// generator API
						fragment = generator.GeneratorFragment2 {}
			
						// formatter API
						�IF fromExistingEcoreModels�
						fragment = adapter.FragmentAdapter {
							fragment = ecore2xtext.FormatterFragment auto-inject {}
						}
						�ELSE�
							fragment = formatting.Formatter2Fragment2 {}
						�ENDIF�
						
						�IF testProject.enabled�
							fragment = adapter.FragmentAdapter {
								fragment = junit.Junit4Fragment auto-inject {}
							}
						�ENDIF�
						
						�IF config.uiProject.enabled�
							fragment = builder.BuilderIntegrationFragment2 auto-inject {}
							// labeling API
							fragment = adapter.FragmentAdapter {
								fragment = labeling.LabelProviderFragment auto-inject {}
							}
							
							// outline API
							fragment = adapter.FragmentAdapter {
								fragment = outline.OutlineTreeProviderFragment auto-inject {}
							}
							fragment = adapter.FragmentAdapter {
								fragment = outline.QuickOutlineFragment auto-inject {}
							}
							
							// quickfix API
							fragment = adapter.FragmentAdapter {
								fragment = quickfix.QuickfixProviderFragment auto-inject {}
							}
							
							// content assist API
							fragment = adapter.FragmentAdapter {
								fragment = contentAssist.ContentAssistFragment auto-inject {}
							}
							
							// provides a preference page for template proposals
							fragment = adapter.FragmentAdapter {
								fragment = templates.CodetemplatesGeneratorFragment auto-inject {}
							}
							
							// rename refactoring
							fragment = adapter.FragmentAdapter {
								fragment = refactoring.RefactorElementNameFragment auto-inject {}
							}
							
							// provides a compare view
							fragment = adapter.FragmentAdapter {
								fragment = compare.CompareFragment auto-inject {}
							}
						�ENDIF�
						�IF  config.uiProject.enabled || config.ideProject.enabled�
							// generates a more lightweight Antlr parser and lexer tailored for content assist
							fragment = adapter.FragmentAdapter {
								fragment = parser.antlr.XtextAntlrUiGeneratorFragment auto-inject {}
							}
						�ENDIF�
						// provides the necessary bindings for java types integration
						fragment = adapter.FragmentAdapter {
							fragment = types.TypesGeneratorFragment auto-inject {}
						}
			
						// generates the required bindings only if the grammar inherits from Xbase
						fragment = xbase.XbaseGeneratorFragment2 auto-inject {}
			
						// generates the required bindings only if the grammar inherits from Xtype
						fragment = xbase.XtypeGeneratorFragment2 auto-inject {}

						�IF config.intellijProject.enabled�
							// Intellij IDEA integration
							fragment = idea.IdeaPluginGenerator auto-inject {}
							fragment = idea.parser.antlr.XtextAntlrIDEAGeneratorFragment auto-inject {}
						�ENDIF�
						
						�IF config.webProject.enabled�
							// web integration
							fragment = web.WebIntegrationFragment auto-inject {
								framework = "Ace"
								generateServlet = true
								generateJettyLauncher = true
								generateHtmlExample = true
							}
						�ENDIF�
					}
				}
			}
		'''
	}
	
	private def isFromExistingEcoreModels() {
		!config.ecore2Xtext.EPackageInfos.isEmpty
	}
	
	override buildGradle() {
		super.buildGradle => [
			additionalContent = '''
				configurations {
					mwe2 {
						extendsFrom compile
					}
				}

				dependencies {
					mwe2 "org.eclipse.xtext:org.eclipse.xtext.xtext:${xtextVersion}"
					mwe2 "org.eclipse.xtext:org.eclipse.xtext.xtext.generator:${xtextVersion}"
				}
				
				task generateXtextLanguage(type: JavaExec) {
					main = 'org.eclipse.emf.mwe2.launch.runtime.Mwe2Launcher'
					classpath = configurations.mwe2
					inputs.file "�Outlet.MAIN_RESOURCES.sourceFolder�/�workflowFilePath�"
					inputs.file "�Outlet.MAIN_RESOURCES.sourceFolder�/�grammarFilePath�"
					outputs.dir "�Outlet.MAIN_SRC_GEN.sourceFolder�"
					args += "�Outlet.MAIN_RESOURCES.sourceFolder�/�workflowFilePath�"
					args += "-p"
					args += "runtimeProject=/${projectDir}"
				}
				
				compileXtend.dependsOn(generateXtextLanguage)
				clean.dependsOn(cleanGenerateXtextLanguage)
				eclipse.classpath.plusConfigurations += [configurations.mwe2]
			'''
		]
	}
		
	override pom() {
		super.pom => [
			packaging = if (isEclipsePluginProject) "eclipse-plugin" else "jar"
			buildSection = '''
				<build>
					<plugins>
						<plugin>
							<groupId>org.codehaus.mojo</groupId>
							<artifactId>exec-maven-plugin</artifactId>
							<version>1.2.1</version>
							<executions>
								<execution>
									<id>mwe2Launcher</id>
									<phase>generate-sources</phase>
									<goals>
										<goal>java</goal>
									</goals>
								</execution>
							</executions>
							<configuration>
								<mainClass>org.eclipse.emf.mwe2.launch.runtime.Mwe2Launcher</mainClass>
								<arguments>
									<argument>/${project.basedir}/�Outlet.MAIN_RESOURCES.sourceFolder�/�workflowFilePath�</argument>
									<argument>-p</argument>
									<argument>runtimeProject=/${project.basedir}</argument>
								</arguments>
								<includePluginDependencies>true</includePluginDependencies>
							</configuration>
							<dependencies>
								<dependency>
									<groupId>org.eclipse.xtext</groupId>
									<artifactId>org.eclipse.xtext.xtext</artifactId>
									<version>${xtextVersion}</version>
								</dependency>
								<dependency>
									<groupId>org.eclipse.xtext</groupId>
									<artifactId>org.eclipse.xtext.xtext.generator</artifactId>
									<version>${xtextVersion}</version>
								</dependency>
								<dependency>
									<groupId>org.eclipse.xtext</groupId>
									<artifactId>org.eclipse.xtext.xbase</artifactId>
									<version>${xtextVersion}</version>
								</dependency>
							</dependencies>
						</plugin>
						<plugin>
							<groupId>org.eclipse.xtend</groupId>
							<artifactId>xtend-maven-plugin</artifactId>
						</plugin>

						<plugin>
							<groupId>org.apache.maven.plugins</groupId>
							<artifactId>maven-clean-plugin</artifactId>
							<version>2.5</version>
							<configuration>
								<filesets combine.children="append">
									<fileset>
										<directory>${basedir}/�Outlet.MAIN_SRC_GEN.sourceFolder�/</directory>
									</fileset>
									<fileset>
										<directory>${basedir}/model/generated/</directory>
									</fileset>
									�IF config.ideProject.enabled�
										<fileset>
											<directory>${basedir}/../${project.artifactId}.ide/�Outlet.MAIN_SRC_GEN.sourceFolder�/</directory>
										</fileset>
									�ENDIF�
									�IF config.uiProject.enabled�
										<fileset>
											<directory>${basedir}/../${project.artifactId}.ui/�Outlet.MAIN_SRC_GEN.sourceFolder�/</directory>
										</fileset>
									�ENDIF�
									�IF config.webProject.enabled�
										<fileset>
											<directory>${basedir}/../${project.artifactId}.web/�Outlet.MAIN_SRC_GEN.sourceFolder�/</directory>
										</fileset>
									�ENDIF�
								</filesets>
							</configuration>
						</plugin>
					</plugins>
				</build>
			'''
		]
	}
}