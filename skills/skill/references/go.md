# Go

## Structure
**Libraries:**
```
project/
├── main.go  ├── go.mod  ├── Makefile  ├── sample.env
├── models/  ├── methods/interface.go  ├── hooks/  ├── handlers/
├── lib/  ├── utils/  ├── db/  └── tests/
```
**Applications:**
```
project/
├── main.go  ├── go.mod  ├── Makefile  ├── .env.example
└── internal/
    ├── models/  ├── config/  ├── ai/  ├── discord/
    ├── google/  ├── store/  └── worker/
```

## Interface First
```go
// methods/interface.go
type BkashService interface {
    GetToken() (*models.TokenResponse, error)
    CreatePayment(*models.CreateRequest, *models.TokenResponse) (*models.CreatePaymentResponse, error)
}
// Constructor returns interface, not concrete type
func GetBkash(appKey, appSecret string, isLive bool) methods.BkashService {
    return &methods.Bkash{AppKey: appKey, IsLiveStore: isLive}
}
```

## Error Handling
```go
if !utils.RequireNonEmpty(b.AppKey, b.AppSecret) {
    return nil, common.ErrEmptyRequiredField
}
if err != nil {
    return fmt.Errorf("fetch reviews: %w", err)
}
```
Bare `return nil, err` when no context adds value; `fmt.Errorf("context: %w", err)` when it does.

## Typed String Constants
```go
type ApprovalStatus string
const (
    StatusPending  ApprovalStatus = "pending"
    StatusApproved ApprovalStatus = "approved"
    StatusRejected ApprovalStatus = "rejected"
)
```

## Constructors That Can Fail
```go
func NewBot(token, channelID string) (*Bot, error) {
    session, err := discordgo.New("Bot " + token)
    if err != nil { return nil, fmt.Errorf("create discord session: %w", err) }
    return &Bot{session: session, channelID: channelID}, nil
}
```

## Concurrent-Safe Structs
```go
type Bot struct {
    session *discordgo.Session
    mu      sync.RWMutex
    pending map[string]*models.PendingApproval
}
func (b *Bot) isUserAllowed(id string) bool {
    b.mu.RLock(); defer b.mu.RUnlock()
    return b.allowedUsers[id]
}
```

## Primary + Fallbacks
```go
type Generator struct { providers map[string]Provider; primary string; fallbacks []string }

for _, name := range append([]string{g.primary}, g.fallbacks...) {
    if resp, err := providers[name].Generate(ctx, req); err == nil { return resp, nil }
}
```

## Map-Based Dispatch
```go
var Handlers = map[string]func(*discordgo.Session, *discordgo.InteractionCreate){
    "help": Help, "points": Points,
}
if fn, ok := Handlers[name]; ok { fn(s, i) }
```

## Graceful Shutdown
```go
sig := make(chan os.Signal, 1)
signal.Notify(sig, os.Interrupt)
<-sig
```

## Logging
```go
func PrintLog(text, status string) {
    switch status {
    case "info":  color.New(color.FgGreen).Println("[+] " + text)
    case "error": color.New(color.FgRed).Println("[-] " + text)
    case "warn":  color.New(color.FgYellow).Println("[!] " + text)
    default:      color.New(color.FgCyan).Println("[*] " + text)
    }
}
```

## Variadic Field Validator

```go
func RequireNonEmpty(fields ...string) bool {
    for _, f := range fields {
        if f == "" { return false }
    }
    return true
}
```

## URL Construction

Use `url.ParseRequestURI` + path append, never raw string interpolation:

```go
u, _ := url.ParseRequestURI(baseURL)
u.Path += endpoint
return u.String()
```

## Request Abstraction

Centralize all outbound HTTP in a `hooks.Request` struct to avoid scattered HTTP boilerplate:

```go
payload := &hooks.Request{
    Debug:   b.debug,
    Payload: data,
    Url:     hooks.GenerateURI(b.IsLiveStore, common.GRANT_TOKEN_URI),
}
body, err := hooks.DoRequest(payload)
```

## Panic Recovery in main

```go
defer func() {
    if r := recover(); r != nil {
        fmt.Println("Error: ", r)
    }
}()
```

## Anti-Patterns to Avoid (Go)

- `log.Fatal` outside of `main` or `cmd/`
- Business logic directly in `main.go`
- Switch statements for command dispatch: use `map[string]func`
- Prefix-based Discord commands: always slash commands
- Hard-coded credentials: use `os.Getenv` + `sample.env`
