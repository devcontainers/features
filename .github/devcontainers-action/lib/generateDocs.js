"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateFeaturesDocumentation = void 0;
const fs = __importStar(require("fs"));
const github = __importStar(require("@actions/github"));
const core = __importStar(require("@actions/core"));
const path = __importStar(require("path"));
function generateFeaturesDocumentation(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        fs.readdir(basePath, (err, files) => {
            if (err) {
                core.error(err.message);
                core.setFailed(`failed to generate 'features' documentation ${err.message}`);
                return;
            }
            files.forEach(f => {
                core.info(`Generating docs for feature '${f}'`);
                if (f !== '.' && f !== '..') {
                    const readmePath = path.join(basePath, f, 'README.md');
                    // Reads in feature.json
                    const featureJsonPath = path.join(basePath, f, 'devcontainer-feature.json');
                    if (!fs.existsSync(featureJsonPath)) {
                        core.error(`devcontainer-feature.json not found at path '${featureJsonPath}'`);
                        return;
                    }
                    let featureJson = undefined;
                    try {
                        featureJson = JSON.parse(fs.readFileSync(featureJsonPath, 'utf8'));
                    }
                    catch (err) {
                        core.error(`Failed to parse ${featureJsonPath}: ${err}`);
                        return;
                    }
                    if (!featureJson || !(featureJson === null || featureJson === void 0 ? void 0 : featureJson.id)) {
                        core.error(`devcontainer-feature.json for feature '${f}' does not contain an 'id'`);
                        return;
                    }
                    const ref = github.context.ref;
                    const owner = github.context.repo.owner;
                    const repo = github.context.repo.repo;
                    // Add tag if parseable
                    let versionTag = 'latest';
                    if (ref.includes('refs/tags/')) {
                        versionTag = ref.replace('refs/tags/', '');
                    }
                    const generateOptionsMarkdown = () => {
                        const options = featureJson === null || featureJson === void 0 ? void 0 : featureJson.options;
                        if (!options) {
                            return '';
                        }
                        const keys = Object.keys(options);
                        const contents = keys
                            .map(k => {
                            const val = options[k];
                            return `| ${k} | ${val.description || '-'} | ${val.type || '-'} | ${val.default || '-'} |`;
                        })
                            .join('\n');
                        return ('| Options Id | Description | Type | Default Value |\n' +
                            '|-----|-----|-----|-----|\n' +
                            contents);
                    };
                    const newReadme = README_TEMPLATE.replace('#{nwo}', `${owner}/${repo}`)
                        .replace('#{versionTag}', versionTag)
                        .replace('#{featureId}', featureJson.id)
                        .replace('#{featureName}', featureJson.name
                        ? `${featureJson.name} (${featureJson.id})`
                        : `${featureJson.id}`)
                        .replace('#{featureDescription}', featureJson.description ? featureJson.description : '')
                        .replace('#{optionsTable}', generateOptionsMarkdown());
                    // Remove previous readme
                    if (fs.existsSync(readmePath)) {
                        fs.unlinkSync(readmePath);
                    }
                    // Write new readme
                    fs.writeFileSync(readmePath, newReadme);
                }
            });
        });
    });
}
exports.generateFeaturesDocumentation = generateFeaturesDocumentation;
const README_TEMPLATE = `
# #{featureName}

#{featureDescription}

## Example Usage

\`\`\`json
"features": [
    {
        "id": "#{nwo}/#{featureId}@#{versionTag}",
        "options": {
            "version": "latest"
        }
    }
]
\`\`\`

## Options

#{optionsTable}

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
`;
