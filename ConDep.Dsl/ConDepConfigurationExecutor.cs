using System;
using System.Linq;
using System.Reflection;
using ConDep.Dsl.Model.Config;
using ConDep.Dsl.WebDeploy;
using TinyIoC;

namespace ConDep.Dsl
{
    public class ConDepConfigurationExecutor
    {
        public void Execute(Assembly assembly, ConDepConfig envConfig, ConDepOptions options, WebDeploymentStatus status)
        {
            if (assembly == null) { throw new ArgumentException("assembly"); }
            if (envConfig == null) { throw new ArgumentException("envSettings"); }

            var type = assembly.GetTypes().Where(t => typeof(ConDepDefinitionBase).IsAssignableFrom(t)).FirstOrDefault();
            if (type == null)
            {
                throw new ConDepConfigurationTypeNotFoundException(string.Format("A class inheriting from [{0}] must be present in assembly [{1}] for ConDep to work.", typeof(ConDepDefinitionBase).FullName, assembly.FullName));
            }

            var depObject = assembly.CreateInstance(type.FullName) as ConDepDefinitionBase;
            if (depObject == null) throw new NullReferenceException(string.Format("Instance of configuration class [{0}] in assembly [{1}] is null.", type.FullName, assembly.FullName));

            depObject.Options = options;
            depObject.Status = status;
            depObject.EnvSettings = envConfig;

            IoCBootstrapper.Bootstrap(envConfig);

            var conDepSetup = TinyIoCContainer.Current.Resolve<ISetupConDep>();
            var notification = new Notification();

            depObject.Configure((IProvideForSetup)conDepSetup);

            if (!conDepSetup.IsValid(notification))
            {
                notification.Throw();
            }

            conDepSetup.Execute(options, status);
        }

        public static void ExecuteFromAssembly(Assembly assembly, ConDepConfig envSettings, ConDepOptions options, WebDeploymentStatus status)
        {
            new ConDepConfigurationExecutor().Execute(assembly, envSettings, options, status);
        }
    }
}