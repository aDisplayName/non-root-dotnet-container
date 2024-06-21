using System.ComponentModel;
using System.Diagnostics.CodeAnalysis;
using Spectre.Console.Cli;

var app = new CommandApp<FileAccessCommand>();
return app.Run(args);

internal sealed class FileAccessCommand : Command<FileAccessCommand.Settings>
{
    public sealed class Settings : CommandSettings
    {
        [Description("Path to search. Defaults to current directory.")]
        [CommandArgument(0, "<searchPath>")]
        public string FilePath { get; init; }

        [Description("verb, default to Open")]
        [CommandArgument(1, "[openMode]")]
        [DefaultValue(FileMode.Open)]
        public FileMode Mode { get; init; }

        [Description("action, default to Read")]
        [CommandArgument(2, "[action]")]
        [DefaultValue(FileAccess.Read)]
        public FileAccess Access { get; init; }
    }

    public override int Execute([NotNull] CommandContext context, [NotNull] Settings settings)
    {
        using var file = File.Open(settings.FilePath, settings.Mode, settings.Access, FileShare.Read);

        Console.WriteLine("access granted");

        return 0;
    }
}