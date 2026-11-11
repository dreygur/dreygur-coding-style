# PHP CLI (Symfony Console)

## Structure
```
tool/
├── bin/toolname        # #!/usr/bin/env php entry
├── src/
│   ├── Commands/       # one class per command
│   └── Extensions/     # custom Application
└── composer.json       # "bin": ["bin/toolname"]
```

## CLI Entry
```php
#!/usr/bin/env php
<?php
set_time_limit(0);

foreach ([__DIR__.'/../../vendor/autoload.php', __DIR__.'/../../../../autoload.php', 'vendor/autoload.php'] as $f) {
    if (file_exists($f)) { require $f; break; }
}

$app = new ToolApplication('My CLI', 'v1.0.0');
$app->add(new InstallCommand);
$app->run();
```
`composer.json`: `"bin": ["bin/toolname"]`, `"require": {"symfony/console": "^5.2"}`

## Custom Application: Strip Unused Options
```php
class ToolApplication extends Application {
    protected function getDefaultInputDefinition(): InputDefinition {
        return new InputDefinition([
            new InputArgument('command', InputArgument::REQUIRED, 'Command'),
            new InputOption('--help', '-h', InputOption::VALUE_NONE, 'Help'),
        ]);
    }
}
```

## Command Pattern
```php
class InstallCommand extends Command {
    const Q_INPUT = 1; const Q_CONFIRM = 2; const Q_CHOICE = 3;
    private $input; private $output;

    protected function configure(): void {
        $this->setName('install')->setDescription('Install project')
             ->addArgument('name', InputArgument::REQUIRED, 'Name');
    }
    protected function execute(InputInterface $input, OutputInterface $output): int {
        $this->input = $input; $this->output = $output;
        $name = $this->ask('Project name:', self::Q_INPUT, 'myproject');
        if ($this->ask('Proceed?', self::Q_CONFIRM) === 'yes') {
            $output->writeln('Installing...');
        }
        return Command::SUCCESS;
    }
    private function ask(string $q, int $type, string $default = '', array $opts = []): string {
        $helper = $this->getHelper('question');
        $question = match($type) {
            self::Q_INPUT   => new Question($q, $default),
            self::Q_CONFIRM => new ChoiceQuestion($q, ['yes','no'], $default),
            self::Q_CHOICE  => new ChoiceQuestion($q, $opts, $default),
        };
        return $helper->ask($this->input, $this->output, $question);
    }
}
```
`$output->writeln()`, never `echo`. Return `Command::SUCCESS`/`Command::FAILURE`.

## Shelling Out + State
```php
// Escape every interpolated value. Unprivileged port, never sudo.
$host = escapeshellarg("{$domain}:8080");
$root = escapeshellarg("{$domain}/");
passthru("php -S {$host} -t {$root}");

// State as JSON
file_put_contents("{$name}.json", json_encode(['domain' => $domain], JSON_PRETTY_PRINT));
if (file_exists("{$name}.json")) { /* already exists */ }
```

## PHP CLI (Symfony Console) Patterns

### Multi-path Autoload Discovery

```php
foreach ([
    __DIR__ . '/../../vendor/autoload.php',
    __DIR__ . '/../../../../autoload.php',
    'vendor/autoload.php',
] as $file) {
    if (file_exists($file)) { require $file; break; }
}
```

Handles both global (`~/.composer/vendor`) and local installs.

### Typed Question Dispatch

Never string-compare question type. Use class constants:

```php
const QUESTION_INPUT        = 1;
const QUESTION_CONFIRMATION = 2;
const QUESTION_CHOICE       = 3;
```

Private `ask()` method switches on the constant, so callers never touch Symfony Question classes directly.

## Anti-Patterns to Avoid (PHP CLI)

- `echo` in commands: use `$output->writeln()`
- Missing `set_time_limit(0)` in CLI entry
- No shebang (`#!/usr/bin/env php`) in bin file
- bin file not listed in `composer.json` `"bin"` key
- Question logic scattered inline: always a private `ask()` helper
- Not storing `$input`/`$output` as properties when helpers need them
- Not stripping unused Symfony Console options (override `getDefaultInputDefinition()`)
